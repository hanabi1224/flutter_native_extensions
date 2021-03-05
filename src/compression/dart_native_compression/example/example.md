## Getting Started

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

## To get more examples
Go to [unit test](https://github.com/hanabi1224/flutter_native_extensions/blob/master/src/compression/dart_native_compression/test/lz4_test.dart)