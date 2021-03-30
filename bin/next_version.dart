import 'package:file/local.dart';
import 'package:release_tools/next_version_runner.dart';
import 'package:release_tools/runner_runner.dart';

const fs = LocalFileSystem();

Future<void> main(List<String> arguments) async {
  final rr = RunnerRunner();
  final runner = NextVersionRunner(git: rr.git, printer: rr.printer);
  await rr.run(runner, arguments);
}
