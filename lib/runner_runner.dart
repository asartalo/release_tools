import 'dart:io';
import 'package:file/local.dart';

import 'exec.dart';
import 'git_exec.dart';
import 'printer.dart';
import 'runner.dart';

const fs = LocalFileSystem();

class RunnerRunner {
  final printer = TruePrinter(stdout: stdout, stderr: stderr);
  final String workingDir = fs.path.canonicalize(Directory.current.path);
  GitExec? _gitExec;
  GitExec get git => _gitExec ??= GitExec(Exec(workingDir: workingDir));

  Future<void> run(Runner runner, List<String> arguments) async {
    exitCode = 0;
    try {
      await runner.run(arguments);
    } catch (e) {
      exitCode = 1;
      printer.printErr(e.toString());
      return;
    }
  }
}
