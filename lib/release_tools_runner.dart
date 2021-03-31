import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'git_exec.dart';
import 'next_version_command.dart';
import 'printer.dart';
import 'runner.dart';
import 'update_version_command.dart';

typedef RunnerBuilder = Runner Function();

class ReleaseToolsRunner extends Runner {
  final GitExec git;
  final String workingDir;
  final Printer printer;
  final FileSystem fs;

  late final Map<String, RunnerBuilder> builders;

  ReleaseToolsRunner({
    required this.git,
    required this.workingDir,
    required this.printer,
    required this.fs,
  });

  @override
  Future<void> run(List<String> arguments) async {
    final cmd = CommandRunner("release_tools",
        "A collection of tools to help with creating releases and publishing libraries.")
      ..addCommand(UpdateVersionCommand(
        fs: fs,
        printer: printer,
        workingDir: workingDir,
      ))
      ..addCommand(NextVersionCommand(printer: printer, git: git));

    await cmd.run(arguments);
  }
}
