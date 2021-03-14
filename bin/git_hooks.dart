import 'dart:io';

import 'package:conventional/conventional.dart';
import 'package:git_hooks/git_hooks.dart';

void main(List<String> arguments) {
  final params = {Git.commitMsg: commitMsg, Git.preCommit: preCommit};
  GitHooks.call(arguments, params);
}

Future<bool> commitMsg() async {
  final commitMessage = Utils.getCommitEditMsg();
  final result = lintCommit(commitMessage);
  if (!result.valid) {
    print('COMMIT MESSAGE ERROR: ${result.message}');
  }
  return result.valid;
}

Future<bool> preCommit() async {
  var response = true;
  try {
    final result = await Process.run('dartanalyzer', ['lib']);
    print(result.stdout);
    if (result.exitCode != 0) {
      response = false;
    }
  } catch (e) {
    response = false;
  }
  return response;
}
