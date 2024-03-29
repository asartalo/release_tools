import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';
import 'version_helpers.dart';

class CurrentVersionCommand extends ReleaseToolsCommand with VersionCommand {
  @override
  final Project project;

  @override
  final Printer printer;

  @override
  final name = 'current_version';

  @override
  final description = 'Gets the current version number on pubspec.yaml.';

  @override
  final invocation = 'release_tools current_version';

  @override
  final takesArguments = true;

  @override
  final usageFooter = helpFooter(
    '''
release_tools current_version
''',
  );

  CurrentVersionCommand({
    required this.project,
    required this.printer,
  }) {
    argParser.addFlag(
      'no-build',
      abbr: 'n',
      help: 'Do not include build number/info in output',
      aliases: ['noBuild'],
    );
  }

  @override
  Future<void> run() async {
    final args = ensureArgResults();
    final noBuild = args['no-build'] as bool;

    final currentVersion = await getVersionFromPubspec();
    if (noBuild) {
      printer.printSuccess(versionStringWithoutBuild(currentVersion));
    } else {
      printer.printSuccess(currentVersion);
    }
  }
}
