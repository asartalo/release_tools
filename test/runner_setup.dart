import 'package:file/memory.dart';
import 'package:release_tools/git_exec.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';

class RunnerTestContext {
  final MemoryFileSystem fs;
  final StubPrinter printer;
  final String workingDir;
  final StubGitExec git;
  final ReleaseToolsRunner runner;

  RunnerTestContext({
    required this.fs,
    required this.printer,
    required this.workingDir,
    required this.git,
    required this.runner,
  });
}

typedef GetContext = RunnerTestContext Function({DateTime? now});

typedef SetupCallback = void Function(GetContext);

void runnerSetup(SetupCallback callback) {
  RunnerTestContext ctxCaller({DateTime? now}) {
    final fs = MemoryFileSystem();
    final workingDir = fs.systemTempDirectory.path;
    final printer = StubPrinter();
    final git = StubGitExec();
    final runner = ReleaseToolsRunner(
      git: git,
      workingDir: workingDir,
      printer: printer,
      fs: fs,
      now: now ?? DateTime.now(),
    );
    return RunnerTestContext(
      runner: runner,
      fs: fs,
      workingDir: workingDir,
      printer: printer,
      git: git,
    );
  }

  callback(ctxCaller);
}
