import 'dart:ffi';
import 'dart:io';

final _dylibPrefix = Platform.isWindows ? '' : 'lib';
final _dylibExtension =
    Platform.isWindows ? '.dll' : (Platform.isMacOS ? '.dylib' : '.so');
final _dylibName = '${_dylibPrefix}dart_native_compression$_dylibExtension';
DynamicLibrary? _dylib;

class SetupUtil {
  static Future<DynamicLibrary> getDylibAsync() async {
    await _ensureInitilizedAsync();
    return _dylib!;
  }

  static Future _ensureInitilizedAsync() async {
    if (_dylib != null) {
      return;
    }

    final nativeDir = '../native_compression';
    await Process.run('cargo', ['build', '--release', '--verbose'],
        workingDirectory: nativeDir);
    final dylibPath =
        '${Directory.current.absolute.path}/$nativeDir/target/release/$_dylibName';
    _dylib = DynamicLibrary.open(Uri.file(dylibPath).toFilePath());
  }
}
