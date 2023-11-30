// ignore_for_file: avoid_print
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
  print('Running dart analyzer...');
  var valid = true;
  try {
    final result = await Process.run('dart', ['analyze', 'lib']);
    if (result.exitCode != 0) {
      valid = false;
      print(result.stdout);
    }
  } catch (e) {
    valid = false;
    print(e);
  }
  return valid;
}
