import 'dart:ffi';
import 'dart:io';

final _dylibPrefix = Platform.isWindows ? '' : 'lib';
final _dylibExtension =
    Platform.isWindows ? '.dll' : (Platform.isMacOS ? '.dylib' : '.so');
final _dylibName = '${_dylibPrefix}native_compression$_dylibExtension';
DynamicLibrary _dylib;

class SetupUtil {
  static Future<DynamicLibrary> getDylibAsync() async {
    await _ensureInitilizedAsync();
    return _dylib;
  }

  static Future _ensureInitilizedAsync() async {
    if (_dylib != null) {
      return;
    }

    final nativeDir = '../native_compression';
    await Process.start('cargo', ['build', '--release', '--verbose'],
        workingDirectory: nativeDir);
    _dylib = DynamicLibrary.open('$nativeDir/target/release/$_dylibName');
  }
}
