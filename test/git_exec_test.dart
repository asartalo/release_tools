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
          expect(
            firstCall.join(' '),
            equals('git rev-list --max-parents=0 HEAD'),
          );
        });

        test('passes git log command', () {
          expect(exec.executeArgs[1].first, equals('git'));
          expect(exec.executeArgs[1], contains('$commitId..HEAD'));
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
          expect(exec.executeArgs[0], contains('$commitId..HEAD'));
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
        expect(args.join(' '), equals('git rev-parse foo^{}'));
      });

      test('returns the value from rev-parse', () {
        expect(result, equals(commitId));
      });
    });

    group('lsRemoteTag()', () {
      late String result;
      late String successOutput;

      String getLastExecArgs() {
        final args = exec.executeArgs.last;
        return args.join(' ');
      }

      group('calling', () {
        setUp(() async {
          successOutput = '''
5af48ff5f784176b90fdf6884e925bfd20cb4936	refs/tags/0.2.1
3ed81541a61c7502b658c027f6d5ec87c129c1a9	refs/tags/0.2.2''';
          exec.executioner = (cmd, args) => Execution(
                success: true,
                output: successOutput,
              );
        });

        test('with no tag and no remote', () async {
          result = await git.lsRemoteTag();
          expect(getLastExecArgs(), equals('git ls-remote -q --tags origin'));
        });

        test('with no tag but with remote', () async {
          result = await git.lsRemoteTag(remote: 'foo');
          expect(getLastExecArgs(), equals('git ls-remote -q --tags foo'));
        });

        test('with a tag but with no remote', () async {
          result = await git.lsRemoteTag(tag: '2.0.0');
          expect(
            getLastExecArgs(),
            equals('git ls-remote -q --tags origin 2.0.0'),
          );
        });
      });

      group('returns', () {
        setUp(() async {
          successOutput = '''
5af48ff5f784176b90fdf6884e925bfd20cb4936	refs/tags/0.2.1
3ed81541a61c7502b658c027f6d5ec87c129c1a9	refs/tags/0.2.2''';
          exec.executioner = (cmd, args) => Execution(
                success: true,
                output: successOutput,
              );
          result = await git.lsRemoteTag();
        });

        test('returns the result output', () {
          expect(result, equals(successOutput));
        });
      });
    });
  });
}
