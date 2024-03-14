import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:conventional/conventional.dart';
import 'package:yaml/yaml.dart';

import 'git_exec.dart';
import 'printer.dart';
import 'project.dart';

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
  Project get project;

  Future<String> getVersionFromArgsOrPubspec() async {
    final args = ensureArgResults();
    try {
      return args.rest.isNotEmpty
          ? args.rest.first
          : await getVersionFromPubspec();

      // ignore: avoid_catching_errors
    } on NoPubspecFileFound {
      throw ArgumentError(
        'No pubspec.yaml found. Please provide a version to increment from.',
      );
    }
  }

  Future<String> getVersionFromPubspec() async {
    if (!await project.pubspecExists()) {
      throw NoPubspecFileFound(
        'No pubspec.yaml found.',
      );
    }
    final contents = await project.getPubspecContents();
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

class NoPubspecFileFound extends StateError {
  NoPubspecFileFound(super.message);
}

mixin GitCommand on ReleaseToolsCommand {
  GitExec get git;

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
    return getCommitsFromId(from);
  }

  Future<List<Commit>> getCommitsFromId(String? id) {
    return git.commits(from: id);
  }
}
