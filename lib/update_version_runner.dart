import 'package:file/file.dart';
import 'package:release_tools/printer.dart';
import 'package:yaml/yaml.dart';
import 'package:args/args.dart';

class UpdateVersionRunner {
  final FileSystem fs;
  final String workingDir;
  final Printer printer;
  final ArgParser _parser;

  UpdateVersionRunner({
    required this.fs,
    required this.workingDir,
    required this.printer,
  }) : _parser = ArgParser() {
    _parser.addFlag(
      'help',
      negatable: false,
      abbr: 'h',
      help: 'Display usage information',
    );
  }

  Future<void> run(List<String> arguments) async {
    final parsed = _parser.parse(arguments);
    if (parsed['help'] as bool) {
      showHelpText();
      return;
    }
    final pubspecFile = await _getPubspecFile();
    final newVersion = _getNewVersion(parsed.rest);
    await _updateVersionOnFile(pubspecFile, newVersion);
    printer.println('Updated version to "$newVersion".');
  }

  void showHelpText() {
    printer.println(helpText());
  }

  String _getNewVersion(List<String> arguments) {
    if (arguments.isEmpty) {
      throw ArgumentError(
          'Please provide a version to update the pubspec.yaml to.');
    }
    return arguments.first;
  }

  Future<File> _getPubspecFile() async {
    final pubspecFile = fs.directory(workingDir).childFile('pubspec.yaml');
    if (!await pubspecFile.exists()) {
      throw MissingPubspecError(workingDir);
    }
    return pubspecFile;
  }

  Future<void> _updateVersionOnFile(File pubspecFile, String newVersion) async {
    final contents = await pubspecFile.readAsString();
    final doc = loadYamlNode(contents) as YamlMap;
    final versionNode = doc.nodes['version'];
    if (versionNode is! YamlScalar) {
      throw InvalidPubspecError(
        'The pubspec file does not appear to be valid. Unable to find version.',
      );
    }
    final start = versionNode.span.start.offset;
    final end = versionNode.span.end.offset;
    final newContents = contents.replaceRange(start, end, newVersion);
    await pubspecFile.writeAsString(newContents);
  }

  String helpText() {
    return '''
Updates the version number on a pubspec.yaml file.

Usage:
  - release_tools:update_version <version>
  - release_tools:update_version -h

${_parser.usage}

Example:
  release_tools:update_version 2.0.1

See https://pub.dev/packages/release_tools for more information.
''';
  }
}

class MissingPubspecError extends StateError {
  MissingPubspecError(String workingDir)
      : super('There is no pubspec.yaml in $workingDir');
}

class InvalidPubspecError extends StateError {
  InvalidPubspecError(String message) : super(message);
}
