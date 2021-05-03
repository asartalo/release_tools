import 'package:file/file.dart';

class Project {
  final FileSystem fs;
  final String workingDir;

  Project({
    required this.fs,
    required this.workingDir,
  });

  File getFile(String fileName) {
    return fs.directory(workingDir).childFile(fileName);
  }

  File changelog() {
    return getFile('CHANGELOG.md');
  }

  File pubspec() {
    return getFile('pubspec.yaml');
  }

  Future<bool> pubspecExists() {
    return pubspec().exists();
  }

  Future<void> writeToChangelog(String contents) async {
    await changelog().writeAsString(contents);
  }

  Future<void> writeToPubspec(String contents) async {
    await pubspec().writeAsString(contents);
  }

  Future<String> getPubspecContents() {
    return pubspec().readAsString();
  }
}
