import 'package:args/args.dart';
import 'package:conventional/conventional.dart';
import 'package:pub_semver/pub_semver.dart';

import 'git_exec.dart';
import 'help_footer.dart';
import 'printer.dart';
import 'release_tools_command.dart';

class NextVersionCommand extends ReleaseToolsCommand {
  final GitExec git;

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
release_tools:next_version 2.0.1
release_tools:next_version --from=1571c703742a16bfb34c3e68c5d75b8e1eda339b 2.0.1
''');

  NextVersionCommand({
    required this.git,
    required this.printer,
  }) {
    argParser.addOption(
      'from',
      abbr: 'f',
      help: 'Set the commitId to start collecting commits from',
    );
  }

  @override
  Future<void> run() async {
    if (argResults is ArgResults) {
      final args = argResults!;
      if (args.rest.isEmpty) {
        throw ArgumentError('Please provide a version to increment from.');
      }
      final currentVersion = args.rest.first;
      final from = args['from'] is String ? args['from'] as String : null;
      final commits = await git.commits(from: from);
      final newVersion = nextVersion(Version.parse(currentVersion), commits);
      printer.println(newVersion.toString());
    }
  }
}
