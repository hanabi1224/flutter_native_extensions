import 'package:test/test.dart';

import 'package:dart_native_compression/dart_native_compression.dart';

import 'setup_util.dart';

void main() async {
  final lz4 = Lz4Lib(lib: await SetupUtil.getDylibAsync());
  test('getVersioinNumber', () {
    final version = lz4.getVersioinNumber();
    print('LZ4 version number: $version');
    assert(version > 0);
  });

  test('getVersionString', () {
    final version = lz4.getVersionString();
    print('LZ4 version string: $version');
    assert(version != null && !version.isEmpty);
  });
}
