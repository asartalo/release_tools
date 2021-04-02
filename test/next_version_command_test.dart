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
          'when there is a new feature fix': _T(
            commits: [feat, chore, fix],
            result: '1.1.0',
            description: 'updates minor version',
          ),
          'when there is a breaking change': _T(
            commits: [feat, chore, breaking, fix],
            result: '2.0.0',
            description: 'updates major version',
          ),
        };

        testData.forEach((testDescription, data) {
          group(testDescription, () {
            setUp(() {
              git.commitsResponse = parseCommits(data.commits);
            });

            test(data.description, () async {
              await runner.run([command, originalVersion]);
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
          await pubspecFile.writeAsString('''
name: foo_bar
description: A sample pubspec file._file
version: 2.0.0

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  equatable: ^2.0.0

dev_dependencies:
  test: ^1.14.4
''');
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
                'Gets the next version number based on conventional commits.'),
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
  _T({
    required this.commits,
    required this.result,
    required this.description,
  });
}

List<Commit> parseCommits(List<String> commitList) {
  if (commitList.isEmpty) {
    return [];
  }
  return Commit.parseCommits(commitList.join('\r\n\r\n'));
}
