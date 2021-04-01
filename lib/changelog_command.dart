import 'package:args/args.dart';
import 'package:conventional/conventional.dart';
import 'package:file/file.dart';

import 'git_exec.dart';
import 'help_footer.dart';
import 'printer.dart';
import 'release_tools_command.dart';

class ChangelogCommand extends ReleaseToolsCommand with GitCommand {
  final FileSystem fs;
  final String workingDir;
  final GitExec git;
  final DateTime now;

  @override
  final Printer printer;

  @override
  final name = 'changelog';

  @override
  final description = 'Updates changelog based on conventional commits.';

  @override
  final invocation = 'release_tools next_version [OPTIONS] [current_version]';

  @override
  final takesArguments = true;

  @override
  final usageFooter = helpFooter('''
release_tools changelog 2.0.1
release_tools changelog --from=3682c64 2.0.1
''');

  ChangelogCommand({
    required this.fs,
    required this.git,
    required this.workingDir,
    required this.printer,
    required this.now,
  }) {
    gitFromOption();
  }

  @override
  Future<void> run() async {
    if (argResults is ArgResults) {
      final args = argResults!;
      if (args.rest.isEmpty) {
        throw ArgumentError('Please provide a version to mark the changes.');
      }
      final version = args.rest.first;
      final commits = await getCommits();
      final summary = await writeChangelogToFile(
        commits: commits,
        version: version,
        now: now,
        file: fs.directory(workingDir).childFile('CHANGELOG.md'),
      );
      if (summary is ChangeSummary) {
        printer.println(summary.toMarkdown());
      }
    }
  }
}
