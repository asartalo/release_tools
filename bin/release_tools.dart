import 'package:release_tools/release_tools_runner.dart';
import 'package:release_tools/runner_runner.dart';

Future<void> main(List<String> arguments) async {
  final rr = RunnerRunner();
  final runner = ReleaseToolsRunner(
    git: rr.git,
    printer: rr.printer,
    workingDir: rr.workingDir,
    fs: rr.fs,
  );
  await rr.run(runner, arguments);
}
