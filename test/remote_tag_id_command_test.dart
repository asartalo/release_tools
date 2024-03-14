import 'package:release_tools/git_exec.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:release_tools/remote_tag_id_command.dart';
import 'package:test/test.dart';

import 'runner_setup.dart';

void main() {
  group(RemoteTagIdCommand, () {
    runnerSetup((getContext) {
      late ReleaseToolsRunner runner;
      late StubPrinter printer;
      late StubGitExec git;
      const String command = 'remote_tag_id';

      setUp(() {
        final context = getContext();
        runner = context.runner;
        git = context.git;
        printer = context.printer;
      });

      group('happy paths', () {
        final testData = [
          _LRT(
            description: 'default retrieval of a tag',
            args: ['0.2.2'],
            lrtArgs: {
              'tag': '0.2.2',
              'remote': 'origin',
            },
          ),
          _LRT(
            description: 'retrieve a tag on a different remote',
            args: ['0.2.2', '--remote', 'source'],
            lrtArgs: {
              'tag': '0.2.2',
              'remote': 'source',
            },
          ),
        ];

        for (final data in testData) {
          group(data.description, () {
            setUp(() async {
              // response is not important for this test
              // we're only testing the calls
              git.lsRemoteTagResponse = '''
  3ed81541a61c7502b658c027f6d5ec87c129c1a9	refs/tags/0.2.2''';
              final args = [command];
              args.addAll(data.args);
              await runner.run(args);
            });

            test('passes the tag to git.lsRemoteTag()', () {
              expect(git.lsRemoteTagArgs, data.lrtArgs);
            });
          });
        }
        group('retrieving commit id for a tag', () {
          setUp(() async {
            git.lsRemoteTagResponse = '''
3ed81541a61c7502b658c027f6d5ec87c129c1a9	refs/tags/0.2.2''';
            await runner.run([command, '0.2.2']);
          });

          test('passes the tag to git.lsRemoteTag()', () {
            expect(git.lsRemoteTagArgs, {'tag': '0.2.2', 'remote': 'origin'});
          });

          test('returns the hash', () {
            expect(
              printer.prints.last,
              equals('3ed81541a61c7502b658c027f6d5ec87c129c1a9'),
            );
          });
        });

        test('it prints help text', () async {
          await runner.run([command, '--help']);
          final helpText = printer.prints.join('\n');
          expect(
            helpText,
            contains('Get the commit id of a remote tag for a version'),
          );
          expect(helpText, contains('Usage:'));
        });
      });
    });
  });
}

class _LRT {
  final String description;
  final List<String> args;
  final Map<String, String> lrtArgs;
  _LRT({required this.description, required this.args, required this.lrtArgs});
}
