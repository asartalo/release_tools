import 'package:conventional/conventional.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:release_tools/git_exec.dart';
import 'package:release_tools/next_version_command.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group(NextVersionCommand, () {
    late ReleaseToolsRunner runner;
    late FileSystem fs;
    late String workingDir;
    late StubPrinter printer;
    late StubGitExec git;
    const originalVersion = '1.0.0';

    setUp(() {
      fs = MemoryFileSystem();
      workingDir = fs.systemTempDirectory.path;
      printer = StubPrinter();
      git = StubGitExec();
      runner = ReleaseToolsRunner(
          git: git, workingDir: workingDir, printer: printer, fs: fs);
    });

    group('errors', () {
      test('throws ArgumentError when no version is provided', () {
        expect(() => runner.run(['next_version']), throwsArgumentError);
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
            await runner.run(['next_version', originalVersion]);
            expect(printer.prints.first, equals(data.result));
          });
        });
      });

      test('when a commit id is passed, it passes it to git', () async {
        const commitId = '43cf9b78f77a0180ad408cb87e8a774a530619ce';
        await runner.run(['next_version', '--from', commitId, originalVersion]);
        expect(git.commitsFrom, equals(commitId));
      });

      test('it prints help text', () async {
        await runner.run(['next_version', '--help']);
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
