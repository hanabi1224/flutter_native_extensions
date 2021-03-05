import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

class Uint8ArrayUtils {
  static Uint8List fromPointer(Pointer<Uint8> ptr, int length) {
    final view = ptr.asTypedList(length);
    final builder = BytesBuilder(copy: false);
    builder.add(view);
    return builder.takeBytes();
  }

  static Pointer<Uint8> toPointer(Uint8List bytes) {
    final ptr = malloc.allocate<Uint8>(bytes.length);
    final byteList = ptr.asTypedList(bytes.length);
    byteList.setAll(0, bytes);
    return ptr.cast();
  }
}
