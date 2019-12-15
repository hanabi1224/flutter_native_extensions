import 'dart:ffi';

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
  }

  int Function() _getVersionNumber;
  int getVersioinNumber() => _getVersionNumber();

  Pointer<Utf8> Function() _getVersionString;
  String getVersionString() {
    final ptr = _getVersionString();
    return Utf8.fromUtf8(ptr);
  }
}
