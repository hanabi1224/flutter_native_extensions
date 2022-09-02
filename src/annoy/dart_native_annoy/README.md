# dart_native_annoy
[![Main](https://github.com/hanabi1224/flutter_native_extensions/actions/workflows/main.yml/badge.svg)](https://github.com/hanabi1224/flutter_native_extensions/actions/workflows/main.yml)
======

## [Annoy](https://github.com/spotify/annoy) (Approximate Nearest Neighbors Oh Yeah)

This is a dart binding to rust annoy

```dart
import 'dart:ffi';
import 'package:dart_native_annoy/annoy.dart';

/// Creat factory from DynamicLibrary
final indexFactory = AnnoyIndexFactory(lib: DynamicLibrary.open('libannoy_rs_ffi.so'));

/// Load index
final index = indexFactory.loadIndex(
      'index.euclidean.5d.ann', 5, IndexType.Euclidean)!;

print('size: ${index.size}');

final v3 = index.getItemVector(3);

final nearest = index.getNearest(v0, 5, includeDistance: true);
```

#### To get more examples
Go to [unit test](https://github.com/hanabi1224/flutter_native_extensions/blob/master/src/annoy/dart_native_annoy/test/annoy_test.dart)

## To run unit tests

```bash
pub get && dart run test
```

## To build native lib (libru_annoy.so)

install rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
pull submodules
```bash
git submodule update --init --recursive
```
go to [RuAnnoy](https://github.com/hanabi1224/RuAnnoy/) directory, run
```bash
# without simd
cargo build --release
# with simd
RUSTFLAGS="-Ctarget-feature=+avx" cargo +nightly build --release --all-features
```
to cross compile to different target
```bash
cargo lipo --release --targets=aarch64-apple-ios,x86_64-apple-ios,armv7-apple-ios,armv7s-apple-ios
cargo build --target aarch64-linux-android --release
cargo build --target armv7-linux-androideabi --release
cargo build --target i686-linux-android --release
```
The shared library will be under target/release . It would be libru_annoy.so, ru_annoy.dll, libru_annoy.dylib on linux, windows, osx respectively.
