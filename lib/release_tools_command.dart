import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:conventional/conventional.dart';
import 'package:file/file.dart';
import 'package:release_tools/printer.dart';
import 'package:yaml/yaml.dart';

import 'git_exec.dart';

abstract class ReleaseToolsCommand extends Command {
  Printer get printer;

  @override
  void printUsage() => printer.println(usage);

  ArgResults ensureArgResults() {
    if (argResults is! ArgResults) {
      throw StateError('Unexpected: argResults is null');
    }
    return argResults!;
  }
}

mixin VersionCommand on ReleaseToolsCommand {
  external FileSystem get fs;
  external String get workingDir;

  Future<String> getVersionFromArgsOrPubspec() async {
    final args = ensureArgResults();
    return args.rest.isNotEmpty
        ? args.rest.first
        : await getVersionFromPubspec();
  }

  Future<String> getVersionFromPubspec() async {
    final file = fs.directory(workingDir).childFile('pubspec.yaml');
    if (!await file.exists()) {
      throw ArgumentError(
        'No pubspec.yaml found. Please provide a version to increment from.',
      );
    }
    final contents = await file.readAsString();
    Map yaml;
    try {
      yaml = await loadYaml(contents) as Map;
    } catch (e) {
      throw StateError('The pubspec.yaml does not appear to be valid.');
    }
    final version = yaml['version'];
    if (version is! String) {
      throw StateError('Could not find "version" key on pubspec.yaml');
    }
    return version;
  }
}

mixin GitCommand on ReleaseToolsCommand {
  external GitExec get git;

  void gitFromOption() {
    argParser.addOption(
      'from',
      abbr: 'f',
      help: 'Set the commitId to start collecting commits from',
    );
  }

  Future<List<Commit>> getCommits() async {
    final args = ensureArgResults();
    final from = args['from'] is String ? args['from'] as String : null;
    return git.commits(from: from);
  }
}
