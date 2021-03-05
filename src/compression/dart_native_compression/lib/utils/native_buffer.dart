import 'dart:ffi';

class NativeBufferUtils {
  NativeBufferUtils(DynamicLibrary lib) {
    _createBuffer = lib
        .lookup<NativeFunction<Pointer<Uint8> Function(Uint64)>>(
            'ffi_create_buffer')
        .asFunction();

    _freeBuffer = lib
        .lookup<NativeFunction<Void Function(Pointer<Uint8>, Uint64)>>(
            'ffi_free_buffer')
        .asFunction();
  }

  late Pointer<Uint8> Function(int) _createBuffer;
  Pointer<Uint8> createBuffer(int size) => _createBuffer(size);

  late void Function(Pointer<Uint8>, int) _freeBuffer;
  void freeBuffer(Pointer<Uint8> buffer, int size) => _freeBuffer(buffer, size);
}
