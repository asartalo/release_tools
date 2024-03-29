import 'package:conventional/conventional.dart';
import 'package:pub_semver/pub_semver.dart';

import 'git_exec.dart';
import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';
import 'version_helpers.dart';

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
  final usageFooter = helpFooter(
    '''
release_tools next_version # will check version on pubspec.yaml
release_tools next_version 2.0.1
release_tools next_version --from=3682c64 2.0.1
release_tools next_version --ensure-major 0.2.5 # always version >= 1.0.0
release_tools next_version 2.1.3+24 # 2.1.4+25
release_tools next_version --no-build 2.1.3+24 # 2.1.4
''',
  );

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
      'freeze-build',
      abbr: 'b',
      help: 'Do not increment build number',
      aliases: ['freezeBuild'],
    );
    argParser.addFlag(
      'no-build',
      abbr: 'n',
      help: 'Do not include build number in output',
      aliases: ['noBuild'],
    );
    argParser.addFlag(
      'ensure-major',
      abbr: 'm',
      help: 'Ensure next version >= 1.0.0',
      aliases: ['ensureMajor'],
    );
  }

  @override
  Future<void> run() async {
    final currentVersion = await getVersionFromArgsOrPubspec();
    final args = ensureArgResults();
    final incrementBuild = !(args['freeze-build'] as bool);
    final theNextVersion = await getNextVersionFromString(
      await getCommits(),
      currentVersion,
      incrementBuild: incrementBuild,
      noBuild: args['no-build'] as bool,
      ensureMajor: args['ensure-major'] as bool,
    );
    printer.println(theNextVersion);
  }

  Future<String> getNextVersionFromString(
    List<Commit> commits,
    String currentVersion, {
    bool incrementBuild = false,
    bool noBuild = false,
    bool ensureMajor = false,
  }) async {
    final previousVersion = Version.parse(currentVersion);
    final newVersion = nextVersion(
      previousVersion,
      commits,
      incrementBuild: incrementBuild,
      afterV1: ensureMajor,
    );
    return (noBuild ? versionWithoutBuild(newVersion) : newVersion).toString();
  }
}
