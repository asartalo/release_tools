import 'package:conventional/conventional.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:release_tools/version_helpers.dart';

import 'git_exec.dart';
import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';

class ChangelogCommand extends ReleaseToolsCommand with GitCommand {
  final Project project;
  final DateTime now;

  @override
  final GitExec git;

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
    required this.project,
    required this.git,
    required this.printer,
    required this.now,
  }) {
    gitFromOption();
  }

  @override
  Future<void> run() async {
    final args = ensureArgResults();
    if (args.rest.isEmpty) {
      throw ArgumentError('Please provide a version to mark the changes.');
    }
    final version = args.rest.first;
    final summary = await writeChangelog(
      commits: await getCommits(),
      version: version,
    );
    if (summary is ChangeSummary) {
      printer.println(summary.toMarkdown());
    }
  }

  Future<ChangeSummary?> writeChangelog({
    required List<Commit> commits,
    required String version,
  }) {
    return writeChangelogToFile(
      commits: commits,
      version: versionWithoutBuild(Version.parse(version)).toString(),
      now: now,
      file: project.changelog(),
    );
  }
}
