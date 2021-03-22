import 'dart:io';
import 'package:file/local.dart';
import 'package:release_tools/update_version_runner.dart';
import 'package:release_tools/printer.dart';

const fs = LocalFileSystem();

Future<void> main(List<String> arguments) async {
  exitCode = 0;
  final printer = TruePrinter(stdout: stdout, stderr: stderr);
  final workingDir = fs.path.canonicalize(Directory.current.path);
  final runner = UpdateVersionRunner(
    fs: fs,
    workingDir: workingDir,
    printer: printer,
  );

  try {
    await runner.run(arguments);
  } catch (e) {
    exitCode = 1;
    printer.printErr(e.toString());
    return;
  }
}
