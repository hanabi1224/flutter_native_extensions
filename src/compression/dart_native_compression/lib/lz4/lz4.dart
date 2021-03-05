import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_native_compression/utils/uint8_list_utils.dart';
import 'package:ffi/ffi.dart';

typedef get_version_number = Function(Void);

/// Lz4 utility class
class Lz4Lib {
  /// Construct Lz4Lib with DynamicLibrary
  Lz4Lib(DynamicLibrary lib) {
    _getVersionNumber = lib
        .lookup<NativeFunction<Int32 Function()>>('ffi_lz4_version_number')
        .asFunction();

    _getVersionString = lib
        .lookup<NativeFunction<Pointer<Utf8> Function()>>(
            'ffi_lz4_version_string')
        .asFunction();
    _getFrameVersionNumber = lib
        .lookup<NativeFunction<Uint64 Function()>>('ffi_lz4f_get_version')
        .asFunction();

    _getCompressFrameBound = lib
        .lookup<NativeFunction<Uint64 Function(Uint64)>>(
            'ffi_lz4f_compress_frame_bound')
        .asFunction();

    _compressFrame = lib
        .lookup<
            NativeFunction<
                Uint64 Function(Pointer<Uint8>, Uint64, Pointer<Uint8>,
                    Uint64)>>('ffi_lz4f_compress_frame')
        .asFunction();

    _createDecompressionContext = lib
        .lookup<NativeFunction<Uint64 Function(Pointer)>>(
            'ffi_lz4f_create_decompression_context')
        .asFunction();

    _freeDecompressionContext = lib
        .lookup<NativeFunction<Uint64 Function(Pointer)>>(
            'ffi_lz4f_free_decompression_context')
        .asFunction();

    _getFrameHeaderSize = lib
        .lookup<NativeFunction<Uint64 Function(Pointer<Uint8>, Uint64)>>(
            'ffi_lz4f_header_size')
        .asFunction();

    _decompressFrame = lib
        .lookup<
            NativeFunction<
                Uint64 Function(Pointer, Pointer<Uint8>, Pointer<Uint64>,
                    Pointer<Uint8>, Pointer<Uint64>)>>('ffi_lz4f_decompress')
        .asFunction();
  }

  late int Function() _getVersionNumber;

  /// Get lz4 version number
  int getVersioinNumber() => _getVersionNumber();

  late Pointer<Utf8> Function() _getVersionString;

  /// Get lz4 version string
  String getVersionString() {
    final ptr = _getVersionString();
    return ptr.toDartString();
  }

  late int Function() _getFrameVersionNumber;

  /// Get lz4 frame version number
  int getFrameVersionNumber() => _getFrameVersionNumber();

  late int Function(int) _getCompressFrameBound;

  /// Get compression frame bound
  int getCompressFrameBound(int size) => _getCompressFrameBound(size);

  late int Function(Pointer<Uint8>, int, Pointer<Uint8>, int) _compressFrame;

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
  late int Function(Pointer, Pointer<Uint8>, Pointer<Uint64>, Pointer<Uint8>,
      Pointer<Uint64>) _decompressFrame;

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
      srcSizePtr[0] = data.length;
      int srcPtrOffset = 0;
      int nextSrcSize = 0;
      final decompressed = BytesBuilder();
      do {
        dstSizePtr[0] = estimateDstBufferSize;
        nextSrcSize = _decompressFrame(context, dstBuffer, dstSizePtr,
            srcBuffer.elementAt(srcPtrOffset), srcSizePtr);
        final srcSize = srcSizePtr[0];
        srcPtrOffset += srcSize;
        final dstSize = dstSizePtr[0];
        final dstBufferView = dstBuffer.asTypedList(dstSize);
        decompressed.add(dstBufferView);
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

    Pointer<Uint8>? srcBuffer;
    Pointer<Uint8>? dstBuffer;
    int nextSrcSize = 0;
    var sourceBufferBuilder = BytesBuilder();
    var isFirstChunk = true;
    try {
      await for (final chunk in stream) {
        if (isFirstChunk) {
          isFirstChunk = false;
          var srcBuffer = Uint8ArrayUtils.toPointer(chunk);
          estimateDstBufferSize =
              _validateFrameAndGetEstimatedDecodeBufferSize(chunk, srcBuffer);
          dstBuffer = malloc.allocate<Uint8>(estimateDstBufferSize);
        } else if (nextSrcSize == 0) {
          return;
        } else if (nextSrcSize < 0) {
          throw Exception('Error: $nextSrcSize');
        }

        sourceBufferBuilder.add(chunk);
        while (sourceBufferBuilder.length >= nextSrcSize) {
          if (srcBuffer != null) {
            malloc.free(srcBuffer);
            srcBuffer = null;
          }
          if (nextSrcSize == 0) {
            srcBuffer =
                Uint8ArrayUtils.toPointer(sourceBufferBuilder.toBytes());
            srcSizePtr[0] = sourceBufferBuilder.length;
          } else {
            final tmpBuffer = sourceBufferBuilder.toBytes();
            srcBuffer = Uint8ArrayUtils.toPointer(
                Uint8List.view(tmpBuffer.buffer, 0, nextSrcSize));
            srcSizePtr[0] = nextSrcSize;
          }
          dstSizePtr[0] = estimateDstBufferSize;
          nextSrcSize = _decompressFrame(
              context, dstBuffer!, dstSizePtr, srcBuffer, srcSizePtr);
          final consumedSrcSize = srcSizePtr[0];
          if (consumedSrcSize >= sourceBufferBuilder.length) {
            sourceBufferBuilder.clear();
          } else {
            final tmpBuffer = sourceBufferBuilder.takeBytes();
            final remaining = Uint8List.view(tmpBuffer.buffer, consumedSrcSize,
                tmpBuffer.length - consumedSrcSize);
            sourceBufferBuilder.add(remaining);
          }

          final dstSize = dstSizePtr[0];
          final dstBufferView = dstBuffer.asTypedList(dstSize);
          final decompressedChunkBuilder = BytesBuilder(copy: true);
          decompressedChunkBuilder.add(dstBufferView);
          yield decompressedChunkBuilder.takeBytes();
          if (nextSrcSize <= 0) {
            break;
          }
        }
      }
    } finally {
      _freeDecompressionContext(context);
      malloc.free(contextPtr);
      malloc.free(dstSizePtr);
      malloc.free(srcSizePtr);
      if (srcBuffer != null) {
        malloc.free(srcBuffer);
      }
      if (dstBuffer != null) {
        malloc.free(dstBuffer);
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
