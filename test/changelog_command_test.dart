import 'package:conventional/conventional.dart';
import 'package:file/memory.dart';
import 'package:release_tools/changelog_command.dart';
import 'package:release_tools/git_exec.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:test/test.dart';

import 'fixtures.dart';
import 'runner_setup.dart';

void main() {
  group(ChangelogCommand, () {
    final now = DateTime.parse('2021-02-10');
    runnerSetup((getContext) {
      late ReleaseToolsRunner runner;
      late MemoryFileSystem fs;
      late String workingDir;
      late StubPrinter printer;
      late StubGitExec git;
      const command = 'changelog';
      const newVersion = '2.0.0';
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

      Future<String> getChangelogFileContents() async {
        final file =
            fs.file(fs.directory(workingDir).childFile('CHANGELOG.md'));
        return file.readAsString();
      }

      group('errors', () {
        test('throws ArgumentError when no version is provided', () {
          expect(() => runner.run([command]), throwsArgumentError);
        });
      });

      group('happy paths', () {
        final testData = {
          'when there are no commits': _T(
            commits: [],
            result: originalChangelogContent,
            description: 'no version change',
          ),
          'when there are just chores': _T(
            commits: [chore],
            result: originalChangelogContent,
            description: 'no version change',
          ),
          'when there is a bug fix': _T(
            commits: [chore, fix],
            result: '''
# 2.0.0 (2021-02-10)

## Bug Fixes

- plug holes ([cf60800](commit/cf60800))

$originalChangelogContent''',
            description: 'updates version to patch',
          ),
          'when there is a new feature fix': _T(
            commits: [feat, chore],
            result: '''
# 2.0.0 (2021-02-10)

## Features

- it jumps ([925fcd3](commit/925fcd3))

$originalChangelogContent''',
            description: 'updates minor version',
          ),
          'when there is a breaking change': _T(
            commits: [feat, chore, breaking, fix],
            result: '''
# 2.0.0 (2021-02-10)

## Bug Fixes

- plug holes ([cf60800](commit/cf60800))

## Features

- it jumps ([925fcd3](commit/925fcd3))

## BREAKING CHANGES

- null-safety ([43cf9b7](commit/43cf9b7))

$originalChangelogContent''',
            description: 'updates major version',
          ),
        };

        testData.forEach((testDescription, data) {
          group(testDescription, () {
            setUp(() {
              git.commitsResponse = parseCommits(data.commits);
            });

            test(data.description, () async {
              await runner.run([command, newVersion]);
              expect(await getChangelogFileContents(), equals(data.result));
            });
          });
        });

        test('when a commit id is passed, it passes it to git', () async {
          const commitId = '43cf9b7';
          await runner.run([command, '--from', commitId, newVersion]);
          expect(git.commitsFrom, equals(commitId));
        });

        test('prints change summary when successful', () async {
          git.commitsResponse = parseCommits([fix]);
          await runner.run([command, newVersion]);
          expect(printer.prints.last, equals('''
# 2.0.0 (2021-02-10)

## Bug Fixes

- plug holes ([cf60800](commit/cf60800))
'''));
        });

        test('prints nothing when there are no releasable commits', () async {
          git.commitsResponse = parseCommits([docs, chore]);
          await runner.run([command, newVersion]);
          expect(printer.prints.isEmpty, true);
        });

        test('it prints help text', () async {
          await runner.run([command, '--help']);
          final helpText = printer.prints.join('\n');
          expect(
            helpText,
            contains('Updates changelog based on conventional commits.'),
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
