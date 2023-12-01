import 'package:conventional/conventional.dart';
import 'package:file/memory.dart';
import 'package:release_tools/git_exec.dart';
import 'package:release_tools/next_version_command.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:test/test.dart';

import 'fixtures.dart';
import 'runner_setup.dart';

void main() {
  group(NextVersionCommand, () {
    runnerSetup((getContext) {
      late ReleaseToolsRunner runner;
      late MemoryFileSystem fs;
      late String workingDir;
      late StubGitExec git;
      late StubPrinter printer;

      const originalVersion = '1.0.0';
      const command = 'next_version';

      setUp(() {
        final context = getContext();
        runner = context.runner;
        fs = context.fs;
        git = context.git;
        workingDir = context.workingDir;
        printer = context.printer;
      });

      group('errors', () {
        test(
            'throws ArgumentError when no version is provided and no pubspec.yaml is available',
            () {
          expect(() => runner.run([command]), throwsArgumentError);
        });

        test(
            'throws StateError when version key is not present on pubspec.yaml',
            () async {
          final pubspecFile =
              fs.directory(workingDir).childFile('pubspec.yaml');
          await pubspecFile.writeAsString('foo: bar');
          expect(() => runner.run([command]), throwsStateError);
        });

        test('throws StateError when pubspec.yaml is not a valid yaml file',
            () async {
          final pubspecFile =
              fs.directory(workingDir).childFile('pubspec.yaml');
          await pubspecFile.writeAsString(' 113241#');
          expect(() => runner.run([command]), throwsStateError);
        });
      });

      group('happy paths', () {
        final testData = {
          'when there are no commits': _T(
            commits: [],
            result: originalVersion,
            description: 'no version change',
          ),
          'when there are just chores': _T(
            commits: [chore],
            result: originalVersion,
            description: 'no version change',
          ),
          'when there is a bug fix': _T(
            commits: [chore, fix],
            result: '1.0.1',
            description: 'updates version to patch',
          ),
          'when there is a new feature plus fix': _T(
            commits: [feat, chore, fix],
            result: '1.1.0',
            description: 'updates minor version',
          ),
          'when there is a breaking change': _T(
            commits: [feat, chore, breaking, fix],
            result: '2.0.0',
            description: 'updates major version',
          ),
          'when there are no commits and with build number': _T(
            commits: [],
            previousVersion: "1.2.3+1",
            result: "1.2.3+1",
            description: 'no version change',
          ),
          'when there are just chores and with build number': _T(
            commits: [chore],
            previousVersion: "2.2.1+1",
            result: "2.2.1+1",
            description: 'no version change',
          ),
          'when pre-major and there is a bug fix': _T(
            commits: [chore, fix],
            previousVersion: '0.0.1',
            result: '0.0.2',
            description: 'updates version to patch',
          ),
          'when pre-major and there is a new feature plus fix': _T(
            commits: [feat, chore, fix],
            previousVersion: '0.0.1',
            result: '0.0.2',
            description: 'updates version to patch',
          ),
          'when pre-major and there is a breaking change': _T(
            commits: [feat, chore, breaking, fix],
            previousVersion: '0.0.1',
            result: '0.1.0',
            description: 'updates minor version',
          ),
          'when pre-major and there are just chores plus build number': _T(
            commits: [chore],
            previousVersion: '0.0.1+1',
            result: '0.0.1+1',
            description: 'no version change',
          ),

          // ensureMajor
          'when pre-major, ensureMajor flag set but no releasable commits': _T(
            commits: [chore],
            previousVersion: '0.0.1',
            result: '0.0.1',
            ensureMajor: true,
            description: 'no version change',
          ),
          'when pre-major, ensureMajor flag set and there is a fix': _T(
            commits: [chore, fix],
            previousVersion: '0.0.1',
            result: '1.0.0',
            ensureMajor: true,
            description: 'updates version to major version',
          ),
          'when pre-major, ensureMajor flag set and there is feature': _T(
            commits: [chore, feat, fix],
            previousVersion: '0.0.1',
            result: '1.0.0',
            ensureMajor: true,
            description: 'updates version to major version',
          ),
          'when pre-major, ensureMajor flag set and breaking change present':
              _T(
            commits: [feat, chore, breaking, fix],
            previousVersion: '0.0.1',
            result: '1.0.0',
            ensureMajor: true,
            description: 'updates version to major version',
          ),
          'when ensureMajor flag set and there is a new feature plus fix': _T(
            commits: [feat, chore, fix],
            result: '1.1.0',
            ensureMajor: true,
            description: 'updates minor version',
          ),

          'when there is a bug fix and with build number': _T(
            commits: [chore, fix],
            previousVersion: '5.6.7+2',
            result: '5.6.8+3',
            description: 'updates version to patch and increments build number',
          ),
          'when there is a new feature fix and with build number': _T(
            commits: [feat, chore, fix],
            previousVersion: '2.4.6+3',
            result: '2.5.0+4',
            description: 'updates minor version and increments build number',
          ),
          'when there is a breaking change and with build number': _T(
            commits: [feat, chore, breaking, fix],
            previousVersion: '12.34.81+4',
            result: '13.0.0+5',
            description: 'updates major version and increments build number',
          ),
          'when there is a breaking change and with build number with freezeBuild flag':
              _T(
            commits: [feat, chore, breaking, fix],
            freezeBuild: true,
            previousVersion: '12.34.81+4',
            result: '13.0.0+4',
            description:
                'updates major version but does not increment build number',
          ),
          'when there is a breaking change and with build number but passed with noBuild flag':
              _T(
            commits: [feat, chore, breaking, fix],
            noBuild: true,
            previousVersion: '12.34.81+4',
            result: '13.0.0',
            description:
                'updates to next major version but does not include build number',
          ),
        };

        testData.forEach((testDescription, data) {
          group(testDescription, () {
            setUp(() {
              git.commitsResponse = parseCommits(data.commits);
            });

            test(data.description, () async {
              String version;
              if (data.previousVersion is String) {
                version = data.previousVersion!;
              } else {
                version = originalVersion;
              }
              final args = [command];
              if (data.freezeBuild) {
                args.add('--freezeBuild');
              }
              if (data.noBuild) {
                args.add('--noBuild');
              }
              if (data.ensureMajor) {
                args.add('--ensureMajor');
              }
              args.add(version);
              await runner.run(args);
              expect(printer.prints.first, equals(data.result));
            });
          });
        });

        test('when a commit id is passed, it passes it to git', () async {
          const commitId = '43cf9b78f77a0180ad408cb87e8a774a530619ce';
          await runner.run([command, '--from', commitId, originalVersion]);
          expect(git.commitsFrom, equals(commitId));
        });

        test('when no version is set, it uses version on pubspec.yaml',
            () async {
          final pubspecFile =
              fs.directory(workingDir).childFile('pubspec.yaml');
          await pubspecFile.writeAsString(
            '''
name: foo_bar
description: A sample pubspec file._file
version: 2.0.0

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  equatable: ^2.0.0

dev_dependencies:
  test: ^1.14.4
''',
          );
          git.commitsResponse = parseCommits([feat]);
          await runner.run([command]);
          expect(printer.prints.first, equals('2.1.0'));
        });

        test('it prints help text', () async {
          await runner.run([command, '--help']);
          final helpText = printer.prints.join('\n');
          expect(
            helpText,
            contains(
              'Gets the next version number based on conventional commits.',
            ),
          );
          expect(helpText, contains('Usage:'));
        });
      });
    });
  });
}

class _T {
  final List<String> commits;
  final String result;
  final String description;
  final String? previousVersion;
  final bool freezeBuild;
  final bool noBuild;
  final bool ensureMajor;
  _T({
    required this.commits,
    required this.result,
    required this.description,
    this.previousVersion,
    this.freezeBuild = false,
    this.noBuild = false,
    this.ensureMajor = false,
  });
}

List<Commit> parseCommits(List<String> commitList) {
  if (commitList.isEmpty) {
    return [];
  }
  return Commit.parseCommits(commitList.join('\r\n\r\n'));
}
