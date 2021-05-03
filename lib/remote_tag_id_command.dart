import 'package:release_tools/release_tools_command.dart';

import 'git_exec.dart';
import 'help_footer.dart';
import 'printer.dart';

class RemoteTagIdCommand extends ReleaseToolsCommand {
  final GitExec git;

  @override
  final Printer printer;

  @override
  final name = 'remote_tag_id';

  @override
  final description = 'Get the commit id of a remote tag for a version';

  @override
  final invocation = 'release_tools remote_tag_id [OPTIONS] <version>';

  @override
  final takesArguments = true;

  @override
  final usageFooter = helpFooter('''
release_tools remote_tag_id 2.0.1
release_tools remote_tag_id 3.2.8 --remote=source
''');

  RemoteTagIdCommand({
    required this.git,
    required this.printer,
  }) {
    argParser.addOption(
      'remote',
      abbr: 'r',
      help: 'Set the remote parameter',
      defaultsTo: 'origin',
    );
  }

  @override
  Future<void> run() async {
    final args = ensureArgResults();
    final version = args.rest.first;
    final commitId = await getRemoteTagId(version, args['remote'] as String);
    printer.printSuccess(commitId);
  }

  Future<String> getRemoteTagId(String tag, String remote) async {
    final result = await git.lsRemoteTag(
      tag: tag,
      remote: remote,
    );
    return result.split(RegExp(r'\s+')).first;
  }
}
