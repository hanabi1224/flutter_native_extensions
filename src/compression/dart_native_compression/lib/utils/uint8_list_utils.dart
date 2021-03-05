import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

class Uint8ArrayUtils {
  // https://github.com/dart-lang/ffi/issues/31
  // Workaround: before does not allow direct pointer exposure
  static Pointer<Uint8> toPointer(Uint8List bytes) {
    final ptr = malloc.allocate<Uint8>(bytes.length);
    final byteList = ptr.asTypedList(bytes.length);
    byteList.setAll(0, bytes);
    return ptr.cast();
  }
}

class NativeBytesBuilder {
  int _pos = 0;
  late int _capacity;
  late Pointer<Uint8> ptr;
  bool _needFree = true;
  NativeBytesBuilder(this._capacity) {
    ptr = malloc.allocate(_capacity);
  }

  NativeBytesBuilder._fromPointer(
      Pointer<Uint8> this.ptr, this._capacity, this._pos) {
    _needFree = false;
  }

  get capacity => _capacity;
  get length => _pos;

  List<int> add(List<int> bytes) {
    if (_pos >= _capacity) {
      return bytes;
    }
    List<int> remainder = [];
    if (bytes.length > 0) {
      var maxAllowed = _capacity - _pos;
      late List<int> bytesToSet;
      if (maxAllowed < bytes.length) {
        bytesToSet = bytes.sublist(0, maxAllowed);
        remainder = bytes.sublist(maxAllowed);
      } else {
        bytesToSet = bytes;
      }

      for (var i = 0; i < bytesToSet.length; i++) {
        ptr[_pos++] = bytesToSet[i];
      }
    }
    return remainder;
  }

  Uint8List asTypedList() {
    return ptr.asTypedList(length);
  }

  NativeBytesBuilder shift(int offset) {
    return NativeBytesBuilder._fromPointer(
        ptr.elementAt(offset), _capacity - offset, _pos - offset);
  }

  void free() {
    if (_needFree) {
      malloc.free(ptr);
    }
  }
}
