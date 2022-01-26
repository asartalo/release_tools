import 'package:conventional/conventional.dart';
import 'package:release_tools/changelog_command.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/remote_tag_id_command.dart';
import 'package:release_tools/update_version_command.dart';
import 'package:release_tools/version_helpers.dart';

import 'next_version_command.dart';
import 'release_tools_command.dart';

class PrepareReleaseCommand extends ReleaseToolsCommand {
  @override
  final String description = 'Prepares the project for release.';

  @override
  final String name = 'prepare_release';

  @override
  final Printer printer;

  final NextVersionCommand nextVersionCommand;
  final RemoteTagIdCommand remoteTagIdCommand;
  final ChangelogCommand changelogCommand;
  final UpdateVersionCommand updateVersionCommand;

  PrepareReleaseCommand({
    required this.printer,
    required this.nextVersionCommand,
    required this.remoteTagIdCommand,
    required this.changelogCommand,
    required this.updateVersionCommand,
  }) {
    argParser.addFlag(
      'writeSummary',
      abbr: 'w',
      help:
          'Writes release information to files (VERSION.txt and RELEASE_SUMMARY.txt)',
    );
  }

  @override
  Future<void> run() async {
    final currentVersion = await nextVersionCommand.getVersionFromPubspec();
    final currentVersionWithoutBuild =
        versionStringWithoutBuild(currentVersion);
    final tagId = await remoteTagIdCommand.getRemoteTagId(
      currentVersionWithoutBuild,
      'origin',
    );
    final commits = await changelogCommand.getCommitsFromId(
      tagId.isEmpty ? null : tagId,
    );
    final nextVersion = await nextVersionCommand.getNextVersionFromString(
      commits,
      currentVersion,
      incrementBuild: true,
    );
    if (nextVersion != currentVersion) {
      await _createRelease(
        commits: commits,
        nextVersion: nextVersion,
      );
    } else {
      printer.println('There are no releasable commits');
    }
  }

  Future<void> _createRelease({
    required List<Commit> commits,
    required String nextVersion,
  }) async {
    final args = ensureArgResults();
    final summary = await changelogCommand.writeChangelog(
      commits: commits,
      version: nextVersion,
    );

    await updateVersionCommand.updateVersionOnPubspecFile(nextVersion);
    if (summary is ChangeSummary) {
      if (args['writeSummary'] as bool) {
        final project = changelogCommand.project;
        final versionFile = project.getFile('VERSION.txt');
        await versionFile.writeAsString(nextVersion);

        final summaryFile = project.getFile('RELEASE_SUMMARY.txt');
        await summaryFile.writeAsString(summary.toMarkdown());
      }

      printer.printSuccess('Version bumped to: $nextVersion\n');
      printer.println('SUMMARY:\n\n${summary.toMarkdown()}');
    }
  }
}
