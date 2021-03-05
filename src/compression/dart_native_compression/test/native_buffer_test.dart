import 'package:dart_native_compression/utils/native_buffer.dart';
import 'package:dart_native_compression/utils/uint8_list_utils.dart';
import 'package:test/test.dart';

import 'setup_util.dart';

void main() async {
  final nativeBufferUtils = NativeBufferUtils(await SetupUtil.getDylibAsync());
  test('create_and_free', () {
    final bufferSize = 1024;
    final buffer = nativeBufferUtils.createBuffer(bufferSize);
    nativeBufferUtils.freeBuffer(buffer, 1024);
  });

  test('NativeBytesBuilder1', () {
    _testNativeBytesBuilder(0, 10);
  });

  test('NativeBytesBuilder2', () {
    _testNativeBytesBuilder(8, 10);
  });

  test('NativeBytesBuilder3', () {
    _testNativeBytesBuilder(10, 10);
  });

  test('NativeBytesBuilder4', () {
    _testNativeBytesBuilder(11, 10);
  });

  test('NativeBytesBuilder5', () {
    _testNativeBytesBuilder(19, 10);
  });

  test('NativeBytesBuilder6', () {
    _testNativeBytesBuilder(20, 10);
  });

  test('NativeBytesBuilder7', () {
    _testNativeBytesBuilder(22, 10);
  });
}

void _testNativeBytesBuilder(int listSize, int bufferSize) {
  var remainder = List.filled(listSize, 0);
  var buffer = NativeBytesBuilder(bufferSize);
  var count = 0;
  while (remainder.length > 0) {
    remainder = buffer.add(remainder);
    buffer.free();
    buffer = NativeBytesBuilder(bufferSize);
    count += 1;
  }
  final expected = (listSize + bufferSize - 1) / bufferSize;
  expect(count, expected.toInt());
}
