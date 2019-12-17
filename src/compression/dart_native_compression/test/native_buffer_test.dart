
import 'package:dart_native_compression/utils/native_buffer.dart';
import 'package:test/test.dart';

import 'setup_util.dart';

void main() async {
  final nativeBufferUtils =
      NativeBufferUtils(lib: await SetupUtil.getDylibAsync());
  test('create_and_free', () {
    final bufferSize = 1024;
    final buffer = nativeBufferUtils.createBuffer(bufferSize);
    nativeBufferUtils.freeBuffer(buffer, 1024);
  });
}
