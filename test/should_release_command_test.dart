import 'package:conventional/conventional.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:release_tools/git_exec.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:release_tools/should_release_command.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group(ShouldReleaseCommand, () {
    late ReleaseToolsRunner runner;
    late FileSystem fs;
    late String workingDir;
    late StubPrinter printer;
    late StubGitExec git;
    const String command = 'should_release';

    setUp(() {
      fs = MemoryFileSystem();
      workingDir = fs.systemTempDirectory.path;
      printer = StubPrinter();
      git = StubGitExec();
      runner = ReleaseToolsRunner(
          git: git, workingDir: workingDir, printer: printer, fs: fs);
    });

    group('happy paths', () {
      final testData = {
        'when there are no commits': _T(
          commits: [],
          result: 'no',
          description: 'no version change',
        ),
        'when there are just chores': _T(
          commits: [chore],
          result: 'no',
          description: 'no version change',
        ),
        'when there is a bug fix': _T(
          commits: [chore, fix],
          result: 'yes',
          description: 'updates version to patch',
        ),
        'when there is a new feature fix': _T(
          commits: [feat, chore, fix],
          result: 'yes',
          description: 'updates minor version',
        ),
        'when there is a breaking change': _T(
          commits: [feat, chore, breaking, fix],
          result: 'yes',
          description: 'updates major version',
        ),
      };

      testData.forEach((testDescription, data) {
        group(testDescription, () {
          setUp(() {
            git.commitsResponse = parseCommits(data.commits);
          });

          test(data.description, () async {
            await runner.run([command]);
            expect(printer.prints.first, equals(data.result));
          });
        });
      });

      test('when a commit id is passed, it passes it to git', () async {
        const commitId = '43cf9b78f77a0180ad408cb87e8a774a530619ce';
        await runner.run([command, '--from', commitId]);
        expect(git.commitsFrom, equals(commitId));
      });

      test('it prints help text', () async {
        await runner.run([command, '--help']);
        final helpText = printer.prints.join('\n');
        expect(
          helpText,
          contains('Checks if a release is possible based on commits'),
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
