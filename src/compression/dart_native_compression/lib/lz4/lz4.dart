import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_native_compression/utils/uint8_list_utils.dart';
import 'package:ffi/ffi.dart';

typedef GetVersionNumberNative = Int32 Function();
typedef GetVersionNumber = int Function();

typedef GetVersionStringNative = Pointer<Utf8> Function();
typedef GetVersionString = Pointer<Utf8> Function();

typedef GetFrameVersionNumberNative = Uint64 Function();
typedef GetFrameVersionNumber = int Function();

typedef GetCompressFrameBoundNative = Uint64 Function(Uint64);
typedef GetCompressFrameBound = int Function(int);

typedef CompressFrameNative = Uint64 Function(
    Pointer<Uint8>, Uint64, Pointer<Uint8>, Uint64);
typedef CompressFrame = int Function(Pointer<Uint8>, int, Pointer<Uint8>, int);

typedef DecompressFrameNative = Uint64 Function(
    Pointer, Pointer<Uint8>, Pointer<Uint64>, Pointer<Uint8>, Pointer<Uint64>);
typedef DecompressFrame = int Function(
    Pointer, Pointer<Uint8>, Pointer<Uint64>, Pointer<Uint8>, Pointer<Uint64>);

/// Lz4 utility class
class Lz4Lib {
  /// Construct Lz4Lib with DynamicLibrary
  Lz4Lib(DynamicLibrary lib) {
    getVersionNumber =
        lib.lookupFunction<GetVersionNumberNative, GetVersionNumber>(
            'ffi_lz4_version_number');

    _getVersionString =
        lib.lookupFunction<GetVersionStringNative, GetVersionString>(
            'ffi_lz4_version_string');

    getFrameVersionNumber =
        lib.lookupFunction<GetFrameVersionNumberNative, GetFrameVersionNumber>(
            'ffi_lz4f_get_version');

    getCompressFrameBound =
        lib.lookupFunction<GetCompressFrameBoundNative, GetCompressFrameBound>(
            'ffi_lz4f_compress_frame_bound');

    _compressFrame = lib.lookupFunction<CompressFrameNative, CompressFrame>(
        'ffi_lz4f_compress_frame');

    _createDecompressionContext =
        lib.lookupFunction<Uint64 Function(Pointer), int Function(Pointer)>(
            'ffi_lz4f_create_decompression_context');

    _freeDecompressionContext =
        lib.lookupFunction<Uint64 Function(Pointer), int Function(Pointer)>(
            'ffi_lz4f_free_decompression_context');

    _getFrameHeaderSize = lib.lookupFunction<
        Uint64 Function(Pointer<Uint8>, Uint64),
        int Function(Pointer<Uint8>, int)>('ffi_lz4f_header_size');

    _decompressFrame =
        lib.lookupFunction<DecompressFrameNative, DecompressFrame>(
            'ffi_lz4f_decompress');
  }

  /// Get lz4 version number
  late GetVersionNumber getVersionNumber;

  late GetVersionString _getVersionString;

  /// Get lz4 version string
  String getVersionString() {
    final ptr = _getVersionString();
    return ptr.toDartString();
  }

  /// Get lz4 frame version number
  late GetFrameVersionNumber getFrameVersionNumber;

  /// Get compression frame bound
  late GetCompressFrameBound getCompressFrameBound;

  late CompressFrame _compressFrame;

  /// Compression data into lz4 frame
  Uint8List compressFrame(Uint8List data) {
    final bound = getCompressFrameBound(data.length);
    final srcBuffer = Uint8ArrayUtils.toPointer(data);
    try {
      final dstBuffer = malloc.allocate<Uint8>(bound);
      final compressedLength =
          _compressFrame(dstBuffer, bound, srcBuffer, data.length);
      return dstBuffer.asTypedList(compressedLength);
    } finally {
      malloc.free(srcBuffer);
    }
  }

  late int Function(Pointer) _createDecompressionContext;
  late int Function(Pointer) _freeDecompressionContext;
  late int Function(Pointer<Uint8>, int) _getFrameHeaderSize;
  late DecompressFrame _decompressFrame;

  /// Decompression data from lz4 frame
  Uint8List decompressFrame(Uint8List data) {
    if (!ListEquality().equals(_magickHeader, data.sublist(0, 4)) ||
        data.length < 7) {
      throw Exception('Invalid data');
    }

    final srcBuffer = Uint8ArrayUtils.toPointer(data);
    final estimateDstBufferSize =
        _validateFrameAndGetEstimatedDecodeBufferSize(data, srcBuffer);

    final contextPtr = malloc.allocate<Uint64>(1);
    _createDecompressionContext(contextPtr);
    final context = Pointer.fromAddress(contextPtr[0]);

    final dstSizePtr = malloc.allocate<Uint64>(1);
    final srcSizePtr = malloc.allocate<Uint64>(1);

    final dstBuffer = malloc.allocate<Uint8>(estimateDstBufferSize);

    try {
      srcSizePtr.value = data.length;
      int srcPtrOffset = 0;
      int nextSrcSize = 0;
      final decompressed = BytesBuilder(copy: true);
      do {
        dstSizePtr.value = estimateDstBufferSize;
        nextSrcSize = _decompressFrame(context, dstBuffer, dstSizePtr,
            srcBuffer.elementAt(srcPtrOffset), srcSizePtr);
        final srcSize = srcSizePtr.value;
        srcPtrOffset += srcSize;
        final dstSize = dstSizePtr.value;
        decompressed.add(dstBuffer.asTypedList(dstSize));
      } while (nextSrcSize > 0);
      return decompressed.takeBytes();
    } finally {
      _freeDecompressionContext(context);
      malloc.free(contextPtr);
      malloc.free(dstSizePtr);
      malloc.free(srcSizePtr);
      malloc.free(srcBuffer);
      malloc.free(dstBuffer);
    }
  }

  /// Decompression data from lz4 frame with stream api
  /// https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
  Stream<Uint8List> decompressFrameStream(Stream<Uint8List> stream) async* {
    final contextPtr = malloc.allocate<Uint64>(1);
    _createDecompressionContext(contextPtr);
    final context = Pointer.fromAddress(contextPtr[0]);

    final dstSizePtr = malloc.allocate<Uint64>(1);
    final srcSizePtr = malloc.allocate<Uint64>(1);

    var estimateDstBufferSize = 0;

    Pointer<Uint8>? dstBuffer;
    int nextSrcSize = 0;
    NativeBytesBuilder? sourceBufferBuilder;
    List<NativeBytesBuilder> danglePointers = [];
    try {
      var remainder = BytesBuilder(copy: true);
      await for (final chunk in stream) {
        if (sourceBufferBuilder == null) {
          sourceBufferBuilder = NativeBytesBuilder(chunk.length);
          sourceBufferBuilder.add(chunk);
          estimateDstBufferSize = _validateFrameAndGetEstimatedDecodeBufferSize(
              chunk, sourceBufferBuilder.ptr);
          dstBuffer = malloc.allocate<Uint8>(estimateDstBufferSize);
        } else {
          var r = sourceBufferBuilder.add(chunk);
          if (r.length > 0) {
            remainder.add(r);
          }
        }

        while (sourceBufferBuilder!.length >= nextSrcSize) {
          srcSizePtr.value = sourceBufferBuilder.length;
          dstSizePtr.value = estimateDstBufferSize;
          nextSrcSize = _decompressFrame(context, dstBuffer!, dstSizePtr,
              sourceBufferBuilder.ptr, srcSizePtr);
          final dstSize = dstSizePtr.value;
          final decompressedChunkBuilder = BytesBuilder(copy: true);
          decompressedChunkBuilder.add(dstBuffer.asTypedList(dstSize));
          yield decompressedChunkBuilder.takeBytes();
          if (nextSrcSize > 0) {
            final consumedSrcSize = srcSizePtr.value;
            if (consumedSrcSize < sourceBufferBuilder.length) {
              if (consumedSrcSize + nextSrcSize <
                  sourceBufferBuilder.capacity) {
                danglePointers.add(sourceBufferBuilder);
                sourceBufferBuilder =
                    sourceBufferBuilder.shift(consumedSrcSize);
              } else {
                remainder.add(
                    sourceBufferBuilder.asTypedList().sublist(consumedSrcSize));
                sourceBufferBuilder.free();
                sourceBufferBuilder = NativeBytesBuilder(nextSrcSize);
              }
            } else {
              sourceBufferBuilder.free();
              sourceBufferBuilder = NativeBytesBuilder(nextSrcSize);
            }
            if (remainder.length > 0) {
              final r = sourceBufferBuilder.add(remainder.takeBytes());
              remainder.clear();
              if (r.length > 0) {
                remainder.add(r);
              }
            }
          } else {
            return;
          }
        }
      }
    } finally {
      _freeDecompressionContext(context);
      malloc.free(contextPtr);
      malloc.free(dstSizePtr);
      malloc.free(srcSizePtr);
      if (dstBuffer != null) {
        malloc.free(dstBuffer);
      }
      if (sourceBufferBuilder != null) {
        sourceBufferBuilder.free();
      }
      for (final p in danglePointers) {
        p.free();
      }
    }
  }

  List<int> _magickHeader = [4, 34, 77, 24];
  Map<int, int> _blockSizeTable = {
    4: 1024 * 64,
    5: 1024 * 256,
    6: 1024 * 1024,
    7: 1024 * 1024 * 4,
  };
  int _validateFrameAndGetEstimatedDecodeBufferSize(
      Uint8List chunk, Pointer<Uint8> chunkPtr) {
    if (!ListEquality().equals(_magickHeader, chunk.sublist(0, 4)) ||
        chunk.length < 7) {
      throw Exception('First chunk too small');
    }

    var estimateDstBufferSize = 0;
    final flagByte = chunk[4];
    final hasContentSize = flagByte & 0x08 > 0;
    final hasDictId = flagByte & 0x01 > 0;
    final headerSize = _getFrameHeaderSize(chunkPtr, chunk.length);
    if (hasContentSize) {
      var contentSizeBytes = headerSize - 3;
      if (hasDictId) {
        contentSizeBytes -= 4;
      }

      if (contentSizeBytes > 0) {
        for (var i = 0; i < contentSizeBytes; i++) {
          estimateDstBufferSize += (chunk[6 + i] << (8 * i));
        }
      }
    }

    final blockMaxSizeKey = chunk[5] >> 4 & 0x07;
    if (_blockSizeTable.containsKey(blockMaxSizeKey)) {
      final blockMaxSize = _blockSizeTable[blockMaxSizeKey]!;
      if (estimateDstBufferSize == 0 || estimateDstBufferSize > blockMaxSize) {
        estimateDstBufferSize = blockMaxSize;
      }
    }

    if (estimateDstBufferSize == 0) {
      estimateDstBufferSize = _blockSizeTable[7]!;
    }

    return estimateDstBufferSize;
  }
}
