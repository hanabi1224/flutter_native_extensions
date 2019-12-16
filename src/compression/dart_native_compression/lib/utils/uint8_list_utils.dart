import 'dart:ffi';
import 'package:ffi/ffi.dart';

class Uint8ArrayUtils {
  static List<int> fromPointer(Pointer<Uint8> ptr, int length) {
    final view = ptr.asTypedList(length);
    final buffer = List<int>();
    for (var i = 0; i < length; i++) {
      buffer.add(view[i]);
    }

    return buffer;
  }

  static Pointer<Uint8> toPointer(List<int> buffer) {
    final ptr = allocate<Uint8>(count: buffer.length);
    final byteList = ptr.asTypedList(buffer.length);
    byteList.setAll(0, buffer);
    return ptr.cast();
  }
}
