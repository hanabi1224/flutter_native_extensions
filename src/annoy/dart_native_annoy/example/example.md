## Getting Started

```dart
import 'dart:ffi';
import 'package:dart_native_annoy/annoy.dart';

/// Creat factory from DynamicLibrary
final fac = AnnoyIndexFactory(lib: DynamicLibrary.open('libru_annoy.so'));

/// Load index
final index = indexFactory.loadIndex(
      'index.euclidean.5d.ann', 5, IndexType.Euclidean)!;

print('size: ${index.size}');

final v3 = index.getItemVector(3);

final nearest = index.getNearest(v0, 5, includeDistance: true);
```

## To get more examples
Go to [unit test](https://github.com/hanabi1224/flutter_native_extensions/blob/master/src/annoy/dart_native_annoy/test/annoy_test.dart)
