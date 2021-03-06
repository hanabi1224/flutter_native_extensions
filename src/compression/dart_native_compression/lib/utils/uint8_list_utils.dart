import 'dart:ffi';
import 'dart:math';
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

class NativeBytesBuilder {
  int _pos = 0;
  late final int capacity;
  late Pointer<Uint8> ptr;
  bool _needFree = true;
  NativeBytesBuilder(this.capacity) {
    ptr = malloc.allocate(capacity);
  }

  NativeBytesBuilder._fromPointer(this.ptr, this.capacity, this._pos) {
    _needFree = false;
  }

  int get length => _pos;

  List<int>? add(List<int> bytes) {
    if (_pos >= capacity) {
      return bytes;
    }
    List<int>? remainder;
    if (bytes.isNotEmpty) {
      var maxAllowed = capacity - _pos;
      if (maxAllowed < bytes.length) {
        remainder = bytes.sublist(maxAllowed);
      }
      for (var i = 0; i < min(maxAllowed, bytes.length); i++) {
        ptr[_pos++] = bytes[i];
      }
    }
    return remainder;
  }

  Uint8List asTypedList() {
    return ptr.asTypedList(length);
  }

  NativeBytesBuilder shift(int offset) {
    return NativeBytesBuilder._fromPointer(
        ptr.elementAt(offset), capacity - offset, _pos - offset);
  }

  void free() {
    if (_needFree) {
      malloc.free(ptr);
    }
  }
}
