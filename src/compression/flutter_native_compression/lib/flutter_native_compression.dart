import 'dart:ffi';
import 'dart:io';

import 'package:dart_native_compression/dart_native_compression.dart';

class FlutterNativeCompression {
  static final Lz4Lib lz4 = Lz4Lib(
      lib: Platform.isAndroid
          ? DynamicLibrary.open('libdart_native_compression.so')
          : DynamicLibrary.process());
}
