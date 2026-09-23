import 'dart:io';

/// Updates the app version in all files checked by CI.
///
/// Usage: fvm dart run release.dart 1.18.1+61
void main(List<String> args) {
  if (args.length != 1) {
    print('Usage: fvm dart run release.dart <version>+<build>');
    exit(1);
  }

  final match = RegExp(r'^(\d+\.\d+\.\d+)\+(\d+)$').firstMatch(args.first);
  if (match == null) {
    print('Invalid version "${args.first}", expected e.g. 1.18.1+61');
    exit(1);
  }
  final version = match.group(1)!;
  final build = int.parse(match.group(2)!);

  /// MSIX package versions only allow 0..65535 per numeric part, so date
  /// versions like 1.0.20260920 become 1.0.2026.920.
  String msixVersion() {
    final dateMatch = RegExp(r'^(\d+)\.(\d+)\.(\d{8})$').firstMatch(version);
    if (dateMatch == null) {
      return '$version.0';
    }
    final year = dateMatch.group(3)!.substring(0, 4);
    final monthDay = int.parse(dateMatch.group(3)!.substring(4));
    return '${dateMatch.group(1)}.${dateMatch.group(2)}.$year.$monthDay';
  }

  final root = File(Platform.script.toFilePath()).parent.parent.parent.path;

  _replace(
    file: '$root/app/pubspec.yaml',
    pattern: r'^version: .+$',
    replacement: 'version: $version+$build',
  );
  _replace(
    file: '$root/cli/Cargo.toml',
    pattern: r'^version = ".+"$',
    replacement: 'version = "$version"',
  );
  _replace(
    file: '$root/Cargo.lock',
    pattern: 'name = "lightingsend-cli"\nversion = ".+"',
    replacement: 'name = "lightingsend-cli"\nversion = "$version"',
  );
  _replace(
    file: '$root/support/scripts/compile_windows_exe-inno.iss',
    pattern: r'^#define MyAppVersion ".+"$',
    replacement: '#define MyAppVersion "$version"',
  );
  _replace(
    file: '$root/support/scripts/compile_windows_nsis.nsi',
    pattern: r'^  !define VERSION ".+"$',
    replacement: '  !define VERSION "$version"',
  );
  _replace(
    file: '$root/support/scripts/compile_windows_nsis.nsi',
    pattern: r'^  !define VI_VERSION ".+"$',
    replacement: '  !define VI_VERSION "${msixVersion()}"',
  );
  _replace(
    file: '$root/support/build/msix/content/AppxManifest.xml',
    pattern: r'(?<= )Version="[0-9.]+"',
    replacement: 'Version="${msixVersion()}"',
  );
  _replace(
    file: '$root/support/build/appimage/AppImageBuilder_x86_64.yml',
    pattern: r'^    version: .+$',
    replacement: '    version: $version',
  );
  _replace(
    file: '$root/support/build/appimage/AppImageBuilder_arm_64.yml',
    pattern: r'^    version: .+$',
    replacement: '    version: $version',
  );

  print('Updated to $version+$build');
}

void _replace({required String file, required String pattern, required String replacement}) {
  final regex = RegExp(pattern, multiLine: true);
  final content = File(file).readAsStringSync();
  if (!regex.hasMatch(content)) {
    print('Pattern not found in $file');
    exit(1);
  }
  File(file).writeAsStringSync(content.replaceFirst(regex, replacement));
  print('$file: $replacement');
}
