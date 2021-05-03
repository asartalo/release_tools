import 'package:conventional/conventional.dart';
import 'package:pub_semver/pub_semver.dart';

import 'git_exec.dart';
import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';

class NextVersionCommand extends ReleaseToolsCommand
    with GitCommand, VersionCommand {
  @override
  final GitExec git;

  @override
  final Project project;

  @override
  final Printer printer;

  @override
  final name = 'next_version';

  @override
  final description =
      'Gets the next version number based on conventional commits.';

  @override
  final invocation = 'release_tools next_version [OPTIONS] [current_version]';

  @override
  final takesArguments = true;

  @override
  final usageFooter = helpFooter('''
release_tools next_version # will check version on pubspec.yaml
release_tools next_version 2.0.1
release_tools next_version --from=3682c64 2.0.1
''');

  NextVersionCommand({
    required this.git,
    required this.project,
    required this.printer,
  }) {
    gitFromOption();
  }

  @override
  Future<void> run() async {
    final currentVersion = await getVersionFromArgsOrPubspec();
    printer.println(
      await getNextVersionFromString(
        await getCommits(),
        currentVersion,
      ),
    );
  }

  Future<String> getNextVersionFromString(
    List<Commit> commits,
    String currentVersion,
  ) async {
    final newVersion = nextVersion(Version.parse(currentVersion), commits);
    return newVersion.toString();
  }
}
