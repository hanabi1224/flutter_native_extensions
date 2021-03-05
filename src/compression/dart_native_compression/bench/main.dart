// Create a new benchmark by extending BenchmarkBase
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dart_native_compression/dart_native_compression.dart';

final _dylibPrefix = Platform.isWindows ? '' : 'lib';
final _dylibExtension =
    Platform.isWindows ? '.dll' : (Platform.isMacOS ? '.dylib' : '.so');
final _dylibName = '${_dylibPrefix}dart_native_compression$_dylibExtension';
DynamicLibrary? _dylib;
Lz4Lib? _lz4;
Uint8List? _compressed;

class AsyncBenchmarkBase {
  final String name;
  final ScoreEmitter emitter;

  // Empty constructor.
  const AsyncBenchmarkBase(String name,
      {ScoreEmitter emitter: const PrintEmitter()})
      : this.name = name,
        this.emitter = emitter;

  // The benchmark code.
  // This function is not used, if both [warmup] and [exercise] are overwritten.
  Future run() async {}

  // Runs a short version of the benchmark. By default invokes [run] once.
  Future warmup() async {
    await run();
  }

  // Exercices the benchmark. By default invokes [run] 10 times.
  Future exercise() async {
    for (int i = 0; i < 10; i++) {
      await run();
    }
  }

  // Not measured setup code executed prior to the benchmark runs.
  void setup() {}

  // Not measures teardown code executed after the benchark runs.
  void teardown() {}

  // Measures the score for this benchmark by executing it repeately until
  // time minimum has been reached.
  static Future<double> measureFor(Function f, int minimumMillis) async {
    int minimumMicros = minimumMillis * 1000;
    int iter = 0;
    Stopwatch watch = new Stopwatch();
    watch.start();
    int elapsed = 0;
    while (elapsed < minimumMicros) {
      await f();
      elapsed = watch.elapsedMicroseconds;
      iter++;
    }
    return elapsed / iter;
  }

  // Measures the score for the benchmark and returns it.
  Future<double> measure() async {
    setup();
    // Warmup for at least 100ms. Discard result.
    measureFor(() async {
      await this.warmup();
    }, 100);
    // Run the benchmark for at least 2000ms.
    double result = await measureFor(() async {
      await this.exercise();
    }, 2000);
    teardown();
    return result;
  }

  Future report() async {
    emitter.emit(name, await measure());
  }
}

class LZ4DecompressFrameBenchmark extends BenchmarkBase {
  LZ4DecompressFrameBenchmark() : super("decompressFrameOneShot");
  void run() {
    _lz4!.decompressFrame(_compressed!);
  }
}

class LZ4DecompressFrameStreamBenchmark extends AsyncBenchmarkBase {
  LZ4DecompressFrameStreamBenchmark()
      : super("decompressFrameStreamWithSmallChunk");
  Future run() async {
    final decompressedBuilder = BytesBuilder(copy: true);
    final compressedStream = _splitDataIntoChunks(_compressed!, 11);
    await for (final decompressedChunk
        in _lz4!.decompressFrameStream(compressedStream)) {
      decompressedBuilder.add(decompressedChunk);
    }
  }
}

class LZ4DecompressFrameStream2Benchmark extends AsyncBenchmarkBase {
  LZ4DecompressFrameStream2Benchmark()
      : super("decompressFrameStreamWithLargeChunk");
  Future run() async {
    final decompressedBuilder = BytesBuilder(copy: true);
    final compressedStream =
        _splitDataIntoChunks(_compressed!, 1024 * 1024 * 11);
    await for (final decompressedChunk
        in _lz4!.decompressFrameStream(compressedStream)) {
      decompressedBuilder.add(decompressedChunk);
    }
  }
}

void main() async {
  print('Compiling native code...');
  await _compileNative();
  _lz4 = Lz4Lib(_dylib!);
  print('Compressing data...');
  await _setupCompressed();

  print('Running benchmark...');
  LZ4DecompressFrameBenchmark().report();
  await LZ4DecompressFrameStreamBenchmark().report();
  await LZ4DecompressFrameStream2Benchmark().report();
}

Future _compileNative() async {
  final nativeDir = '../../native_compression';
  await Process.run('cargo', ['build', '--release', '--verbose'],
      workingDirectory: nativeDir);
  final dylibPath =
      '${Directory.current.absolute.path}/$nativeDir/target/release/$_dylibName';
  _dylib = DynamicLibrary.open(Uri.file(dylibPath).toFilePath());
}

Future _setupCompressed() async {
  final src = await File.fromUri(Uri.file('../dickens')).readAsBytesSync();
  _compressed = _lz4!.compressFrame(src);
}

Stream<Uint8List> _splitDataIntoChunks(Uint8List data, int chunkSize) async* {
  final byteBuffer = data.buffer;
  for (var i = 0; chunkSize * i < byteBuffer.lengthInBytes; i++) {
    final chunk = Uint8List.view(byteBuffer, chunkSize * i,
        min(byteBuffer.lengthInBytes - (chunkSize * i), chunkSize));
    if (chunk.length > 0) {
      yield chunk;
    } else {
      break;
    }
  }
}
