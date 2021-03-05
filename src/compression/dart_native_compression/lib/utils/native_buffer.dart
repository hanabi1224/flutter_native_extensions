import 'dart:ffi';

typedef CreateBufferNative = Pointer<Uint8> Function(Uint64);
typedef CreateBuffer = Pointer<Uint8> Function(int);
typedef FreeBufferNative = Void Function(Pointer<Uint8>, Uint64);
typedef FreeBuffer = void Function(Pointer<Uint8>, int);

class NativeBufferUtils {
  NativeBufferUtils(DynamicLibrary lib) {
    createBuffer = lib
        .lookupFunction<CreateBufferNative, CreateBuffer>('ffi_create_buffer');

    freeBuffer =
        lib.lookupFunction<FreeBufferNative, FreeBuffer>('ffi_free_buffer');
  }

  late CreateBuffer createBuffer;
  late FreeBuffer freeBuffer;
}
