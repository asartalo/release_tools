import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:release_tools/git_exec.dart';
import 'package:release_tools/prepare_release_command.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:test/test.dart';

import 'fixtures.dart';
import 'helpers.dart';
import 'runner_setup.dart';

void main() {
  group(PrepareReleaseCommand, () {
    final now = DateTime.parse('2021-02-10');
    runnerSetup((getContext) {
      late ReleaseToolsRunner runner;
      late MemoryFileSystem fs;
      late String workingDir;
      late StubPrinter printer;
      late StubGitExec git;
      const command = 'prepare_release';
      String getPubspecContents([originalVersion = '1.0.0']) {
        return '''
name: foo_bar
description: A sample pubspec file._file
version: $originalVersion

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  equatable: ^2.0.0

dev_dependencies:
  test: ^1.14.4
''';
      }

      const originalChangelogContent = '''
# 1.0.0 (2021-02-09)

## Features

- eat healthy ([#3](issues/3)) ([cf60800](commit/cf60800))
''';

      setUp(() async {
        final context = getContext(now: now);
        runner = context.runner;
        fs = context.fs;
        git = context.git;
        workingDir = context.workingDir;
        printer = context.printer;

        // prepare changelog
        final file = fs.directory(workingDir).childFile('CHANGELOG.md');
        await file.writeAsString(originalChangelogContent);
      });

      File getFile(String fileName) {
        return fs.directory(workingDir).childFile(fileName);
      }

      Future<String> getChangelogFileContents() async {
        final file = getFile('CHANGELOG.md');
        return file.readAsString();
      }

      Future<void> createPubspec(String contents) async {
        final pubspecFile = getFile('pubspec.yaml');
        await pubspecFile.writeAsString(contents);
      }

      Future<String> readPubspec() {
        final pubspecFile = getFile('pubspec.yaml');
        return pubspecFile.readAsString();
      }

      group('errors', () {
        test('throws StateError when there is no pubspec.yaml is available',
            () {
          expect(() => runner.run([command]), throwsStateError);
        });

        test(
            'throws StateError when version key is not present on pubspec.yaml',
            () async {
          await createPubspec('foo: bar');
          expect(() => runner.run([command]), throwsStateError);
        });

        test('throws StateError when pubspec.yaml is not a valid yaml file',
            () async {
          await createPubspec(' 113241#');
          expect(() => runner.run([command]), throwsStateError);
        });
      });

      group('happy paths', () {
        const expectedSummary = '''
# 2.0.0 (2021-02-10)

## Bug Fixes

- plug holes ([cf60800](commit/cf60800))

## Features

- it jumps ([925fcd3](commit/925fcd3))

## BREAKING CHANGES

- null-safety ([43cf9b7](commit/43cf9b7))
''';
        setUp(() => createPubspec(getPubspecContents()));

        group('when there is a tag from last release', () {
          setUp(() async {
            git.lsRemoteTagResponse = '''
3ed81541a61c7502b658c027f6d5ec87c129c1a9	refs/tags/1.0.0''';
          });

          void logicTest() {
            test('it gets remote tag for the version', () async {
              expect(git.lsRemoteTagArgs['tag'], equals('1.0.0'));
            });

            test('it logs from that tag commit id', () async {
              expect(
                git.commitsFrom,
                equals('3ed81541a61c7502b658c027f6d5ec87c129c1a9'),
              );
            });
          }

          void successTest() {
            logicTest();

            test('it updates pubspec version', () async {
              expect(await readPubspec(), contains('version: 2.0.0'));
            });

            test('it updates changelog', () async {
              expect(
                await getChangelogFileContents(),
                contains(expectedSummary),
              );
            });

            test('it prints the version', () {
              expect(
                printer.prints.join('\n'),
                contains('Version bumped to: 2.0.0'),
              );
            });

            test('it prints the summary', () {
              expect(
                printer.prints.join('\n'),
                contains('SUMMARY:\n\n$expectedSummary'),
              );
            });
          }

          group('with no releasable commits', () {
            setUp(() {
              git.commitsResponse = parseCommits([chore]);
            });

            group('by default', () {
              late String changeLogContents;
              late String pubspecContents;

              setUp(() async {
                changeLogContents =
                    await getFile('CHANGELOG.md').readAsString();
                pubspecContents = await getFile('pubspec.yaml').readAsString();
                await runner.run([command]);
              });

              logicTest();

              test('it does not update the changelog file', () async {
                expect(
                  await getFile('CHANGELOG.md').readAsString(),
                  changeLogContents,
                );
              });

              test('it does not update the pubspec file', () async {
                expect(
                  await getFile('pubspec.yaml').readAsString(),
                  pubspecContents,
                );
              });

              test('it does not print any version text', () {
                expect(
                  printer.prints.join('\n'),
                  isNot(contains('Version bumped to')),
                );
              });

              test('it prints that there are no releasable commits', () {
                expect(
                  printer.prints.join('\n'),
                  contains('There are no releasable commits'),
                );
              });
            });
          });

          group('with releasable commits', () {
            setUp(() {
              git.commitsResponse = parseCommits([feat, chore, breaking, fix]);
            });

            group('by default', () {
              setUp(() async {
                await runner.run([command]);
              });

              successTest();
              test('it does not write a change summary file', () async {
                final summaryFile = getFile('RELEASE_SUMMARY.txt');
                expect(await summaryFile.exists(), false);
              });

              test('it does not write a version file', () async {
                final versionFile = getFile('VERSION.txt');
                expect(await versionFile.exists(), false);
              });
            });

            group('when passed with -w', () {
              setUp(() async {
                await runner.run([command, '-w']);
              });

              successTest();
              test('it writes a change summary file', () async {
                final summaryFile = getFile('RELEASE_SUMMARY.txt');
                expect(
                    await summaryFile.readAsString(), equals(expectedSummary));
              });

              test('it writes a version file', () async {
                final versionFile = getFile('VERSION.txt');
                expect(await versionFile.readAsString(), equals('2.0.0'));
              });
            });
          });
        });

        group('when there is no tag/release from before', () {
          setUp(() async {
            git.lsRemoteTagResponse = '';
            await runner.run([command]);
          });

          test('it gets commits from earliest commit', () {
            expect(git.commitsFrom, equals(null));
          });
        });
      });

      group('happy paths with build number', () {
        const expectedSummary = '''
# 2.0.0 (2021-02-10)

## Bug Fixes

- plug holes ([cf60800](commit/cf60800))

## Features

- it jumps ([925fcd3](commit/925fcd3))

## BREAKING CHANGES

- null-safety ([43cf9b7](commit/43cf9b7))
''';
        setUp(() => createPubspec(getPubspecContents('1.0.0+1')));

        group('when there is a tag from last release', () {
          setUp(() async {
            git.lsRemoteTagResponse = '''
3ed81541a61c7502b658c027f6d5ec87c129c1a9	refs/tags/1.0.0''';
          });

          void logicTest() {
            test('it gets remote tag for the version', () async {
              expect(git.lsRemoteTagArgs['tag'], equals('1.0.0'));
            });

            test('it logs from that tag commit id', () async {
              expect(
                git.commitsFrom,
                equals('3ed81541a61c7502b658c027f6d5ec87c129c1a9'),
              );
            });
          }

          void successTest() {
            logicTest();

            test('it updates pubspec version', () async {
              expect(await readPubspec(), contains('version: 2.0.0+2'));
            });

            test('it updates changelog', () async {
              expect(
                await getChangelogFileContents(),
                contains(expectedSummary),
              );
            });

            test('it prints the version', () {
              expect(
                printer.prints.join('\n'),
                contains('Version bumped to: 2.0.0'),
              );
            });

            test('it prints the summary', () {
              expect(
                printer.prints.join('\n'),
                contains('SUMMARY:\n\n$expectedSummary'),
              );
            });
          }

          group('with releasable commits', () {
            setUp(() {
              git.commitsResponse = parseCommits([feat, chore, breaking, fix]);
            });

            group('when passed with -w', () {
              setUp(() async {
                await runner.run([command, '-w']);
              });

              successTest();

              test('it writes a version file', () async {
                final versionFile = getFile('VERSION.txt');
                expect(await versionFile.readAsString(), equals('2.0.0+2'));
              });
            });
          });
        });

        group('when there is no tag/release from before', () {
          setUp(() async {
            git.lsRemoteTagResponse = '';
            await runner.run([command]);
          });

          test('it gets commits from earliest commit', () {
            expect(git.commitsFrom, equals(null));
          });
        });
      });
    });
  });
}
