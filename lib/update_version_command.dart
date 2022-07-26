import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart';

import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';

// Taken from https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
const validSemverRegex =
    r'\b(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?\b';

const pubspecFile = 'pubspec.yaml';

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
  final usageFooter = helpFooter(
    '''
release_tools update_version 2.0.1
release_tools udpate_version --file="README.md" --template="Current Version: [VERSION]"''',
  );

  UpdateVersionCommand({
    required this.project,
    required this.printer,
  }) {
    argParser.addOption(
      'template',
      abbr: 't',
      help: 'Replace version on file using string template and "[VERSION]"',
      defaultsTo: '',
    );
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Set the file to update',
      defaultsTo: pubspecFile,
    );
  }

  @override
  Future<void> run() async {
    if (argResults is ArgResults) {
      final template = _getTemplate();
      final newVersion = _getNewVersion(argResults!.rest);
      await updateVersionOnFile(
        newVersion,
        file: await _getFile(),
        template: template,
      );
      printer.printSuccess('Updated version to "$newVersion".');
    }
  }

  Future<void> updateVersionOnPubspecFile(String newVersion) async {
    await _updateVersionOnPubspecFile(await _getPubspecFile(), newVersion);
  }

  Future<void> updateVersionOnFile(
    String newVersion, {
    File? file,
    String template = '',
  }) async {
    final theFile = file ?? await _getPubspecFile();
    if (theFile.basename == pubspecFile) {
      await _updateVersionOnPubspecFile(theFile, newVersion);
    } else {
      await _updateVersionOnFileWithTemplate(theFile, template, newVersion);
    }
  }

  String _getNewVersion(List<String> arguments) {
    if (arguments.isEmpty) {
      throw ArgumentError(
        'Please provide a version to update the pubspec.yaml to.',
      );
    }
    return arguments.first;
  }

  String _getTemplate() {
    final template = argResults?['template'];
    if (template is String) {
      return template;
    }
    return '';
  }

  String _getFilePath() {
    final fileArgument = argResults?['file'];
    if (fileArgument is String) {
      return fileArgument;
    }
    return '';
  }

  Future<File> _getFile() async {
    final fileArgument = _getFilePath();
    if (fileArgument != pubspecFile) {
      return project.getFile(fileArgument);
    }
    return _getPubspecFile();
  }

  Future<File> _getPubspecFile() async {
    if (!await project.pubspecExists()) {
      throw MissingPubspecError(project.workingDir);
    }
    return project.pubspec();
  }

  Future<void> _updateVersionOnPubspecFile(
    File pubspecFile,
    String newVersion,
  ) async {
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

Future<void> _updateVersionOnFileWithTemplate(
  File file,
  String template,
  String newVersion,
) async {
  final contents = await file.readAsString();
  await file.writeAsString(
    replaceVersionWithTemplate(contents, template, newVersion),
  );
}

String replaceVersionWithTemplate(
  String contents,
  String template,
  String version,
) {
  if (template == '') {
    final regex = RegExp(validSemverRegex);
    return contents.replaceAll(regex, version);
  }

  final versionPosition = template.indexOf('[VERSION]');
  if (versionPosition == -1) {
    return contents;
  }
  final prefix = template.substring(0, versionPosition);
  final suffix = template.substring(versionPosition + 9);
  final regex = RegExp(
    "(${RegExp.escape(prefix)})($validSemverRegex)(${RegExp.escape(suffix)})",
  );

  return contents.replaceAllMapped(regex, (match) {
    return '${match.group(1)}$version${match.group(8)}';
  });
}

class MissingPubspecError extends StateError {
  MissingPubspecError(String workingDir)
      : super('There is no pubspec.yaml in $workingDir');
}

class MissingFileError extends StateError {
  MissingFileError(String workingDir, String filePath)
      : super('There is no file "$filePath" in $workingDir');
}

class InvalidPubspecError extends StateError {
  InvalidPubspecError(String message) : super(message);
}
