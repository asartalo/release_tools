import 'package:conventional/conventional.dart';

import 'git_exec.dart';
import 'help_footer.dart';
import 'printer.dart';
import 'release_tools_command.dart';

class ShouldReleaseCommand extends ReleaseToolsCommand with GitCommand {
  @override
  final GitExec git;

  @override
  final Printer printer;

  @override
  final name = 'should_release';

  @override
  final description = 'Checks if a release is possible based on commits';

  @override
  final invocation = 'release_tools should_release [OPTIONS]';

  @override
  final takesArguments = true;

  @override
  final usageFooter = helpFooter(
    '''
release_tools should_release
release_tools should_release --from=1571c70
''',
  );

  ShouldReleaseCommand({
    required this.git,
    required this.printer,
  }) {
    gitFromOption();
  }

  @override
  Future<void> run() async {
    final commits = await getCommits();
    printer.println(hasReleasableCommits(commits) ? 'yes' : 'no');
  }
}
