import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';

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
  });

  @override
  Future<void> run() async {
    final currentVersion = await getVersionFromPubspec();
    printer.printSuccess(currentVersion);
  }
}
