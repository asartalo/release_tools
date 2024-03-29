import 'package:conventional/conventional.dart';

import 'changelog_command.dart';
import 'next_version_command.dart';
import 'printer.dart';
import 'release_tools_command.dart';
import 'remote_tag_id_command.dart';
import 'update_version_command.dart';
import 'update_year_command.dart';
import 'version_helpers.dart';

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
  final UpdateYearCommand updateYearCommand;

  PrepareReleaseCommand({
    required this.printer,
    required this.nextVersionCommand,
    required this.remoteTagIdCommand,
    required this.changelogCommand,
    required this.updateVersionCommand,
    required this.updateYearCommand,
  }) {
    argParser.addFlag(
      'writeSummary',
      abbr: 'w',
      help:
          'Writes release information to files (VERSION.txt and RELEASE_SUMMARY.txt)',
    );
    argParser.addFlag(
      'updateYear',
      abbr: 'Y',
      help:
          'Also update year in license files. Better to eave this off if you are not sure.',
    );
    argParser.addFlag(
      'ensureMajor',
      abbr: 'm',
      help: 'Ensure next version >= 1.0.0',
    );
  }

  @override
  Future<void> run() async {
    final args = ensureArgResults();
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
      ensureMajor: args['ensureMajor'] as bool,
    );
    if (nextVersion != currentVersion) {
      await _createRelease(
        commits: commits,
        nextVersion: nextVersion,
        writeSummary: args['writeSummary'] as bool,
        updateYear: args['updateYear'] as bool,
      );
    } else {
      printer.println('There are no releasable commits');
    }
  }

  Future<void> _createRelease({
    required List<Commit> commits,
    required String nextVersion,
    required bool writeSummary,
    required bool updateYear,
  }) async {
    final summary = await changelogCommand.writeChangelog(
      commits: commits,
      version: nextVersion,
    );

    await updateVersionCommand.updateVersionOnFile(nextVersion);

    if (updateYear) {
      await updateYearCommand.updateYearOnFile(null);
    }

    if (summary is ChangeSummary) {
      if (writeSummary) {
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
