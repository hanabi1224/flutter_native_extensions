# dart_native_compression

A new Flutter package project.

## Getting Started

```dart
import 'dart:ffi'
import 'package:dart_native_compression/dart_native_compression.dart';

final lz4 = Lz4Lib(lib: DynamicLibrary.open('libnative_compression.so'));
final version = lz4.getVersioinNumber();
print('LZ4 version number: $version');
```

To build native lib, go to [native_compression](https://github.com/hanabi1224/flutter_native_extensions/tree/master/src/compression/native_compression) directory, run
```bash
cargo build --release
```
The shared library will be under target/release . It would be libnative_compression.so, native_compression.dll, libnative_compression.dylib on linux, windows, osx respectively.
