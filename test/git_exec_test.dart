import 'package:conventional/conventional.dart';
import 'package:release_tools/exec.dart';
import 'package:release_tools/git_exec.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group(GitExec, () {
    late GitExec git;
    late StubExec exec;

    setUp(() {
      exec = StubExec();
      git = GitExec(exec);
    });

    group('commits()', () {
      late List<Commit> commits;
      late String commitId;

      group('when from value is not set', () {
        setUp(() async {
          commitId = 'f23265ea0c8f81b1d05f14249efc4f2fa499de95';
          exec.executioner = (cmd, args) {
            if (args.first == 'rev-list') {
              return Execution(success: true, output: commitId);
            }
            return Execution(
              success: true,
              output: [chore, breaking].join('\r\n\r\n'),
            );
          };
          commits = await git.commits();
        });

        test('it looks for first hash', () {
          final firstCall = exec.executeArgs.first;
          expect(firstCall.first, equals('git'));
          expect(
            firstCall[1].join(' '),
            equals('rev-list --max-parents=0 HEAD'),
          );
        });

        test('passes git log command', () {
          expect(exec.executeArgs[1].first, equals('git'));
          expect(exec.executeArgs[1][1], contains('$commitId..HEAD'));
        });

        test('parses commit logs', () {
          expect(commits.length, equals(2));
          expect(commits.first, isA<Commit>());
        });
      });
      group('when from value is set', () {
        setUp(() async {
          commitId = '4eeb09ac2d181fdb0911341f719cced4dbfefbe0';
          exec.executioner = (cmd, args) {
            if (args.first == 'rev-list') {
              return Execution(success: true, output: commitId);
            }
            return Execution(
              success: true,
              output: [chore, breaking].join('\r\n\r\n'),
            );
          };
          commits = await git.commits(from: commitId);
        });

        test('it does not call for first hash', () {
          expect(exec.executeArgs.length, equals(1));
        });

        test('passes git log command', () {
          expect(exec.executeArgs[0].first, equals('git'));
          expect(exec.executeArgs[0][1], contains('$commitId..HEAD'));
        });
      });
    });

    group('hashForTag()', () {
      late String commitId;
      late String result;
      setUp(() async {
        commitId = '7b44b95a5bbf5e78c8a6d00e8cbfec473055637e';
        exec.executioner = (cmd, args) => Execution(
              success: true,
              output: commitId,
            );
        result = await git.hashForTag('foo');
      });

      test('runs git rev-parse', () {
        final args = exec.executeArgs.first;
        expect(args.first, equals('git'));
        expect(args[1].join(' '), equals('rev-parse foo^{}'));
      });

      test('returns the value from rev-parse', () {
        expect(result, equals(commitId));
      });
    });
  });
}
