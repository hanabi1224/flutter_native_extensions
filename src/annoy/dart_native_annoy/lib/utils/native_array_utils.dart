import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

extension Uint8ListPointer on Uint8List {
  // https://github.com/dart-lang/ffi/issues/31
  // Workaround: before does not allow direct pointer exposure
  Pointer<Uint8> getPointer() {
    final ptr = malloc.allocate<Uint8>(length);
    final byteList = ptr.asTypedList(length);
    byteList.setAll(0, this);
    return ptr.cast();
  }
}

extension Float32ListPointer on Float32List {
  Pointer<Float> getPointer() {
    final ptr = malloc.allocate<Float>(length);
    final byteList = ptr.asTypedList(length);
    byteList.setAll(0, this);
    return ptr.cast();
  }
}

extension Uint64ListPointer on Uint64List {
  Pointer<Uint64> getPointer() {
    final ptr = malloc.allocate<Uint64>(length);
    final byteList = ptr.asTypedList(length);
    byteList.setAll(0, this);
    return ptr.cast();
  }
}
