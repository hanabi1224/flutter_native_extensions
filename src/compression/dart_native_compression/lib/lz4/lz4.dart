import 'dart:ffi';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_native_compression/utils/uint8_list_utils.dart';
import 'package:meta/meta.dart';
import 'package:ffi/ffi.dart';

typedef get_version_number = Function(Void);

class Lz4Lib {
  final DynamicLibrary lib;
  Lz4Lib({@required this.lib}) {
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

  int Function() _getVersionNumber;
  int getVersioinNumber() => _getVersionNumber();

  Pointer<Utf8> Function() _getVersionString;
  String getVersionString() {
    final ptr = _getVersionString();
    return Utf8.fromUtf8(ptr);
  }

  int Function() _getFrameVersionNumber;
  int getFrameVersionNumber() => _getFrameVersionNumber();

  int Function(int) _getCompressFrameBound;
  int getCompressFrameBound(int size) => _getCompressFrameBound(size);

  int Function(Pointer<Uint8>, int, Pointer<Uint8>, int) _compressFrame;
  Uint8List compressFrame(Uint8List data) {
    final bound = getCompressFrameBound(data.length);
    final dstBuffer = allocate<Uint8>(count: bound);
    final srcBuffer = Uint8ArrayUtils.toPointer(data);
    try {
      final compressedLength =
          _compressFrame(dstBuffer, bound, srcBuffer, data.length);
      final list = Uint8ArrayUtils.fromPointer(dstBuffer, compressedLength);
      return Uint8List.fromList(list);
    } finally {
      free(srcBuffer);
      free(dstBuffer);
    }
  }

  int Function(Pointer) _createDecompressionContext;
  int Function(Pointer) _freeDecompressionContext;
  int Function(Pointer<Uint8>, int) _getFrameHeaderSize;
  int Function(Pointer, Pointer<Uint8>, Pointer<Uint64>, Pointer<Uint8>,
      Pointer<Uint64>) _decompressFrame;
  List<int> _magickHeader = [4, 34, 77, 24];
  Map<int, int> _blockSizeTable = {
    4: 1024 * 64,
    5: 1024 * 256,
    6: 1024 * 1024,
    7: 1024 * 1024 * 4,
  };
  Uint8List decompressFrame(Uint8List data) {
    if (!ListEquality().equals(_magickHeader, data.sublist(0, 4)) ||
        data.length < 7) {
      throw Exception('Invalid data');
    }

    // https://github.com/lz4/lz4/blob/v1.9.2/doc/lz4_Frame_format.md
    final flagByte = data[4];
    final hasContentSize = flagByte & 0x08 > 0;
    final hasDictId = flagByte & 0x01 > 0;

    final srcBuffer = Uint8ArrayUtils.toPointer(data);
    final headerSize = _getFrameHeaderSize(srcBuffer, data.length);
    var estimateDstBufferSize = 0;
    if (hasContentSize) {
      var contentSizeBytes = headerSize - 3;
      if (hasDictId) {
        contentSizeBytes -= 4;
      }

      if (contentSizeBytes > 0) {
        for (var i = 0; i < contentSizeBytes; i++) {
          estimateDstBufferSize += (data[6 + i] << (8 * i));
        }
      }
    }

    final blockMaxSizeKey = data[5] >> 4 & 0x07;
    if (_blockSizeTable.containsKey(blockMaxSizeKey)) {
      final blockMaxSize = _blockSizeTable[blockMaxSizeKey];
      if (estimateDstBufferSize == 0 || estimateDstBufferSize > blockMaxSize) {
        estimateDstBufferSize = blockMaxSize;
      }
    }

    if (estimateDstBufferSize == 0) {
      estimateDstBufferSize = _blockSizeTable[7];
    }

    final contextPtr = allocate<Uint64>(count: 1);
    _createDecompressionContext(contextPtr);
    final context = Pointer.fromAddress(contextPtr.elementAt(0).value);

    final dstSizePtr = allocate<Uint64>(count: 1);
    final srcSizePtr = allocate<Uint64>(count: 1);

    final dstBuffer = allocate<Uint8>(count: estimateDstBufferSize);

    try {
      srcSizePtr.asTypedList(1).setAll(0, [data.length]);
      int srcPtrOffset = 0;
      int nextSrcSize = 0;
      final decompressed = List<int>();
      do {
        dstSizePtr.asTypedList(1).setAll(0, [estimateDstBufferSize]);
        nextSrcSize = _decompressFrame(context, dstBuffer, dstSizePtr,
            srcBuffer.elementAt(srcPtrOffset), srcSizePtr);
        final srcSize = srcSizePtr.elementAt(0).value;
        srcPtrOffset += srcSize;
        final dstSize = dstSizePtr.elementAt(0).value;
        final tmpList = Uint8ArrayUtils.fromPointer(dstBuffer, dstSize);
        decompressed.addAll(tmpList);
      } while (nextSrcSize > 0);
      return Uint8List.fromList(decompressed);
    } finally {
      _freeDecompressionContext(context);
      free(contextPtr);
      free(dstSizePtr);
      free(srcSizePtr);
      free(srcBuffer);
      free(dstBuffer);
    }
  }
}
