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
