import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'package:dart_native_compression/dart_native_compression.dart';

import 'setup_util.dart';

void main() async {
  final lz4 = Lz4Lib(await SetupUtil.getDylibAsync());
  test('getVersioinNumber', () {
    final version = lz4.getVersioinNumber();
    print('LZ4 version number: $version');
    assert(version == 10903);
  });

  test('getVersionString', () {
    final version = lz4.getVersionString();
    print('LZ4 version string: $version');
    assert(version == '1.9.3');
  });

  test('getFrameVersionNumber', () {
    final version = lz4.getFrameVersionNumber();
    print('LZ4 frame version: $version');
    assert(version == 100);
  });

  test('getCompressFrameBound', () {
    final bound = lz4.getCompressFrameBound(19);
    print('LZ4 compress frame bound for 19: $bound');
    assert(bound > 0);
  });

  test('decompressFrame', () {
    final src = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 9, 8, 7, 6, 5, 4, 3, 2, 1];
    final compressed = lz4.compressFrame(Uint8List.fromList(src));
    print(compressed);
    assert(compressed.length > 0);
    final decompressed = lz4.decompressFrame(compressed);
    print(decompressed);
    assert(ListEquality().equals(src, decompressed));
  });

  test('decompressFrameMultiBlock', () async {
    // http://sun.aei.polsl.pl/~sdeor/index.php?page=silesia
    final src = await File.fromUri(Uri.file('dickens')).readAsBytesSync();
    print('src: ${src.length}');
    final compressed = lz4.compressFrame(Uint8List.fromList(src));
    print('compressed: ${compressed.length}');
    assert(compressed.length > 0);
    final decompressed = lz4.decompressFrame(compressed);
    print('decompressed: ${decompressed.length}');
    assert(ListEquality().equals(src, decompressed));
  });

  test('decompressFrameStreamMultiBlockSmallChunk', () async {
    // http://sun.aei.polsl.pl/~sdeor/index.php?page=silesia
    final src = await File.fromUri(Uri.file('dickens')).readAsBytesSync();
    print('src: ${src.length}');
    final compressed = lz4.compressFrame(Uint8List.fromList(src));
    print('compressed: ${compressed.length}');
    assert(compressed.length > 0);

    var decompressedChunkNumber = 0;
    final decompressedBuilder = BytesBuilder(copy: false);
    final compressedStream = _splitIntoChunks(compressed, 10);
    await for (final decompressedChunk
        in lz4.decompressFrameStream(compressedStream)) {
      decompressedChunkNumber += 1;
      // print('Decompressed chunk ${decompressedChunkNumber} received.');
      decompressedBuilder.add(decompressedChunk);
    }

    print('decompressed: ${decompressedBuilder.length}');
    assert(ListEquality().equals(src, decompressedBuilder.takeBytes()));
    assert(decompressedChunkNumber > 1);
  });

  test('decompressFrameStreamMultiBlockLargeChunk', () async {
    // http://sun.aei.polsl.pl/~sdeor/index.php?page=silesia
    final src = await File.fromUri(Uri.file('dickens')).readAsBytesSync();
    print('src: ${src.length}');
    final compressed = lz4.compressFrame(Uint8List.fromList(src));
    print('compressed: ${compressed.length}');
    assert(compressed.length > 0);

    var decompressedChunkNumber = 0;
    final decompressedBuilder = BytesBuilder(copy: false);
    final compressedStream = _splitIntoChunks(compressed, 1024 * 1024 * 10);
    await for (final decompressedChunk
        in lz4.decompressFrameStream(compressedStream)) {
      decompressedChunkNumber += 1;
      // print('Decompressed chunk ${decompressedChunkNumber} received.');
      decompressedBuilder.add(decompressedChunk);
    }

    print('decompressed: ${decompressedBuilder.length}');
    assert(ListEquality().equals(src, decompressedBuilder.takeBytes()));
    assert(decompressedChunkNumber > 1);
  });
}

Stream<Uint8List> _splitIntoChunks(Uint8List data, int chunkSize) async* {
  final byteBuffer = data.buffer;
  for (var i = 0; chunkSize * i < byteBuffer.lengthInBytes; i++) {
    final chunk = Uint8List.view(byteBuffer, chunkSize * i,
        min(byteBuffer.lengthInBytes - (chunkSize * i), chunkSize));
    if (chunk.length > 0) {
      yield Uint8List.fromList(chunk);
    } else {
      break;
    }
  }
}
