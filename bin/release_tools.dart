import 'dart:io';
import 'package:file/local.dart';
import 'package:release_tools/exec.dart';
import 'package:release_tools/git_exec.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';

Future<void> main(List<String> arguments) async {
  final printer = TruePrinter(stdout: stdout, stderr: stderr);
  const fs = LocalFileSystem();
  final String workingDir = fs.path.canonicalize(fs.currentDirectory.path);
  final git = GitExec(Exec(workingDir: workingDir));

  final runner = ReleaseToolsRunner(
    git: git,
    printer: printer,
    workingDir: workingDir,
    fs: fs,
    now: DateTime.now(),
  );

  exitCode = 0;
  try {
    await runner.run(arguments);
  } catch (e) {
    exitCode = 1;
    if (e is FormatException) {
      printer.printErr(e.message);
    } else {
      printer.printErr(e.toString());
    }
    return;
  }
}
