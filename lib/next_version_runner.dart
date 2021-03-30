import 'package:args/args.dart';
import 'package:conventional/conventional.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:release_tools/git_exec.dart';
import 'package:release_tools/printer.dart';

import 'runner.dart';

class NextVersionRunner extends Runner {
  final GitExec git;
  final Printer printer;
  final ArgParser _parser;

  NextVersionRunner({
    required this.git,
    required this.printer,
  }) : _parser = ArgParser() {
    _parser.addOption(
      'from',
      abbr: 'f',
      help: 'Set the commitId to start collecting commits from',
    );
    _parser.addFlag(
      'help',
      negatable: false,
      abbr: 'h',
      help: 'Display usage information',
    );
  }

  @override
  Future<void> run(List<String> arguments) async {
    final args = _parser.parse(arguments);
    if (args['help'] is bool && args['help'] as bool) {
      printer.println(helpText());
      return;
    }
    if (args.rest.isEmpty) {
      throw ArgumentError('Please provide a version to increment from.');
    }
    final currentVersion = args.rest.first;
    final from = args['from'] is String ? args['from'] as String : null;
    final commits = await git.commits(from: from);
    final newVersion = nextVersion(Version.parse(currentVersion), commits);
    printer.println(newVersion.toString());
  }

  @override
  String helpText() {
    return '''
Gets the next version number based on commits.

Usage:
  - release_tools:next_version [--from <commitId>] <current_version>
  - release_tools:next_version -h

${_parser.usage}

Example:
  release_tools:next_version 2.0.1
  release_tools:next_version --from=1571c703742a16bfb34c3e68c5d75b8e1eda339b 2.0.1

See https://pub.dev/packages/release_tools for more information.
''';
  }
}
