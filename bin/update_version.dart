import 'package:file/local.dart';
import 'package:release_tools/runner_runner.dart';
import 'package:release_tools/update_version_runner.dart';

const fs = LocalFileSystem();

Future<void> main(List<String> arguments) async {
  final rr = RunnerRunner();
  final runner = UpdateVersionRunner(
    fs: fs,
    workingDir: rr.workingDir,
    printer: rr.printer,
  );
  await rr.run(runner, arguments);
}