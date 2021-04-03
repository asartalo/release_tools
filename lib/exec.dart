import 'dart:io';

abstract class Exec {
  Future<Execution> execute(String cmd, List<String> args);
  factory Exec({required String workingDir}) => _Exec(workingDir: workingDir);
}

class _Exec implements Exec {
  final String workingDir;
  _Exec({required this.workingDir});

  @override
  Future<Execution> execute(String cmd, List<String> args) async {
    bool success = false;
    String output;
    try {
      final result = await Process.run(
        cmd,
        args,
        workingDirectory: workingDir,
      );
      final exitCode = result.exitCode;
      if (exitCode != 0) {
        output = result.stdout.toString();
        output = result.stderr.toString();
        output += 'Command executed code: $exitCode';
        success = false;
      } else {
        output = result.stdout.toString().trim();
        success = true;
      }
    } catch (e, stacktrace) {
      output = '$e\n\n$stacktrace';
      success = false;
    }
    return Execution(
      success: success,
      output: output,
    );
  }
}

class Execution {
  final bool success;
  final String output;

  const Execution({
    required this.success,
    required this.output,
  });
}

typedef Executioner = Execution Function(String, List<String>);

class StubExec implements Exec {
  final List<List<dynamic>> executeArgs = [];
  late Executioner executioner;

  @override
  Future<Execution> execute(String cmd, List<String> args) async {
    executeArgs.add([cmd, args]);
    return executioner(cmd, args);
  }
}
