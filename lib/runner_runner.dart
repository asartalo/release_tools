import 'dart:io';
import 'package:file/file.dart';
import 'package:file/local.dart';

import 'exec.dart';
import 'git_exec.dart';
import 'printer.dart';
import 'runner.dart';

const _fs = LocalFileSystem();

class RunnerRunner {
  final printer = TruePrinter(stdout: stdout, stderr: stderr);
  final String workingDir = _fs.path.canonicalize(_fs.currentDirectory.path);
  final FileSystem fs = _fs;
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
