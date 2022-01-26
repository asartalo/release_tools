import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart';

import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';

class UpdateVersionCommand extends ReleaseToolsCommand {
  final Project project;

  @override
  final Printer printer;

  @override
  final name = 'update_version';

  @override
  final description = 'Updates the version number on a pubspec.yaml file.';

  @override
  final invocation = 'release_tools update_version [current_version]';

  @override
  final takesArguments = true;

  @override
  final usageFooter = helpFooter('release_tools update_version 2.0.1');

  UpdateVersionCommand({
    required this.project,
    required this.printer,
  }) : super();

  @override
  Future<void> run() async {
    if (argResults is ArgResults) {
      final newVersion = _getNewVersion(argResults!.rest);
      await updateVersionOnPubspecFile(newVersion);
      printer.printSuccess('Updated version to "$newVersion".');
    }
  }

  Future<void> updateVersionOnPubspecFile(String newVersion) async {
    final pubspecFile = await _getPubspecFile();
    await _updateVersionOnFile(pubspecFile, newVersion);
  }

  String _getNewVersion(List<String> arguments) {
    if (arguments.isEmpty) {
      throw ArgumentError(
          'Please provide a version to update the pubspec.yaml to.');
    }
    return arguments.first;
  }

  Future<File> _getPubspecFile() async {
    if (!await project.pubspecExists()) {
      throw MissingPubspecError(project.workingDir);
    }
    return project.pubspec();
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
}

class MissingPubspecError extends StateError {
  MissingPubspecError(String workingDir)
      : super('There is no pubspec.yaml in $workingDir');
}

class InvalidPubspecError extends StateError {
  InvalidPubspecError(String message) : super(message);
}
