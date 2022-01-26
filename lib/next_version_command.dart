import 'package:conventional/conventional.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:release_tools/version_helpers.dart';

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
    incrementBuildFromOption();
  }

  void incrementBuildFromOption() {
    argParser.addFlag(
      'freezeBuild',
      abbr: 'b',
      help: 'Do not increment build number',
    );
    argParser.addFlag(
      'noBuild',
      abbr: 'n',
      help: 'Do not include build number in output',
    );
  }

  @override
  Future<void> run() async {
    final currentVersion = await getVersionFromArgsOrPubspec();
    final args = ensureArgResults();
    final incrementBuild = !(args['freezeBuild'] as bool);
    final theNextVersion = await getNextVersionFromString(
      await getCommits(),
      currentVersion,
      incrementBuild: incrementBuild,
      noBuild: args['noBuild'] as bool,
    );
    printer.println(theNextVersion);
  }

  Future<String> getNextVersionFromString(
    List<Commit> commits,
    String currentVersion, {
    bool incrementBuild = false,
    bool noBuild = false,
  }) async {
    final newVersion = nextVersion(
      Version.parse(currentVersion),
      commits,
      incrementBuild: incrementBuild,
    );
    return (noBuild ? versionWithoutBuild(newVersion) : newVersion).toString();
  }
}
