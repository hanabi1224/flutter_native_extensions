# dart_native_compression
[![Main](https://github.com/hanabi1224/flutter_native_extensions/actions/workflows/main.yml/badge.svg)](https://github.com/hanabi1224/flutter_native_extensions/actions/workflows/main.yml)
======

## LZ4

The lz4 in this library is a ffi binding to [lz4](https://github.com/lz4/lz4) v1.9.3, the compressed block and frame format are both interoperable with official C api, as well as [other](https://lz4.github.io/lz4/) interoperable ports, bindings and CLI tools.

#### Getting Started

```dart
import 'dart:ffi';
import 'package:dart_native_compression/dart_native_compression.dart';

final lz4 = Lz4Lib(lib: DynamicLibrary.open('libnative_compression.so'));
print('LZ4 version number: ${lz4.getVersioinNumber()}');
```

#### To compress data into a [lz4 frame](https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md)

```dart
final compressedFrame = lz4.compressFrame(data);
```

#### To decompress a lz4 frame with a single function

```dart
final decompressed = lz4.decompressFrame(compressedFrame);
```

#### To decompress a lz4 frame with stream api

```dart
await for (final decompressedChunk
    in lz4.decompressFrameStream(compressedStream)) {
    // Your logic here
}
```

#### To get more examples
Go to [unit test](https://github.com/hanabi1224/flutter_native_extensions/blob/master/src/compression/dart_native_compression/test/lz4_test.dart)

## To run unit tests

```bash
pub get && pub run test
```

## To build native lib (libnative_compression.so)

install rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
go to [native_compression](https://github.com/hanabi1224/flutter_native_extensions/tree/master/src/compression/native_compression) directory, run
```bash
cargo build --release
```
for different target
```bash
cargo lipo --release --targets=aarch64-apple-ios,x86_64-apple-ios,armv7-apple-ios,armv7s-apple-ios
cargo build --target aarch64-linux-android --release
cargo build --target armv7-linux-androideabi --release
cargo build --target i686-linux-android --release
```
The shared library will be under target/release . It would be libdart_native_compression.so, dart_native_compression.dll, libdart_native_compression.dylib on linux, windows, osx respectively.
