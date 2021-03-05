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
  late Uint8List _view;
  NativeBytesBuilder(this._capacity) {
    ptr = malloc.allocate(_capacity);
    _view = ptr.asTypedList(_capacity);
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
      _view.setAll(_pos, bytesToSet);
      _pos += bytesToSet.length;
    }
    return remainder;
  }

  Uint8List asTypedList() {
    return ptr.asTypedList(length);
  }

  void free() {
    malloc.free(ptr);
  }
}
