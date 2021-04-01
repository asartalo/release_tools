import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:conventional/conventional.dart';
import 'package:release_tools/printer.dart';

import 'git_exec.dart';

abstract class ReleaseToolsCommand extends Command {
  Printer get printer;

  @override
  void printUsage() => printer.println(usage);
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
    if (argResults is! ArgResults) {
      throw StateError('Unexpected: argResults is null');
    }
    final args = argResults!;
    final from = args['from'] is String ? args['from'] as String : null;
    return git.commits(from: from);
  }
}
