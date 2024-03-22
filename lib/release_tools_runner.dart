import 'package:args/command_runner.dart';
import 'package:file/file.dart';

import 'commands/changelog_command.dart';
import 'commands/current_version_command.dart';
import 'commands/license_headers_command.dart';
import 'commands/next_version_command.dart';
import 'commands/prepare_release_command.dart';
import 'commands/remote_tag_id_command.dart';
import 'commands/should_release_command.dart';
import 'commands/update_version_command.dart';
import 'commands/update_year_command.dart';
import 'git_exec.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_version.dart';

class ReleaseToolsRunner {
  final GitExec git;
  final String workingDir;
  final Printer printer;
  final FileSystem fs;
  final DateTime now;

  ReleaseToolsRunner({
    required this.git,
    required this.workingDir,
    required this.printer,
    required this.fs,
    required this.now,
  });

  Future<void> run(List<String> arguments) async {
    final project = Project(fs: fs, workingDir: workingDir);
    final nextVersionCommand = NextVersionCommand(
      project: project,
      printer: printer,
      git: git,
    );
    final remoteTagIdCommand = RemoteTagIdCommand(
      printer: printer,
      git: git,
    );
    final changelogCommand = ChangelogCommand(
      printer: printer,
      project: project,
      git: git,
      now: now,
    );
    final updateVersionCommand = UpdateVersionCommand(
      printer: printer,
      project: project,
    );
    final updateYearCommand = UpdateYearCommand(
      project: project,
      printer: printer,
      now: now,
    );
    final licenseHeadersCommand = LicenseHeadersCommand(
      project: project,
      printer: printer,
      now: now,
    );

    final cmd = CommandRunner(
      "release_tools",
      "A collection of tools to help with creating releases and publishing libraries.",
    )
      ..addCommand(nextVersionCommand)
      ..addCommand(changelogCommand)
      ..addCommand(updateVersionCommand)
      ..addCommand(
        UpdateYearCommand(
          printer: printer,
          project: project,
          now: now,
        ),
      )
      ..addCommand(licenseHeadersCommand)
      ..addCommand(remoteTagIdCommand)
      ..addCommand(
        CurrentVersionCommand(
          printer: printer,
          project: project,
        ),
      )
      ..addCommand(ShouldReleaseCommand(printer: printer, git: git))
      ..addCommand(
        PrepareReleaseCommand(
          printer: printer,
          nextVersionCommand: nextVersionCommand,
          remoteTagIdCommand: remoteTagIdCommand,
          changelogCommand: changelogCommand,
          updateVersionCommand: updateVersionCommand,
          updateYearCommand: updateYearCommand,
        ),
      )
      ..argParser.addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Show release_tools version',
      );
    final args = cmd.argParser.parse(arguments);
    if (args['version'] as bool) {
      printer.println(releaseToolsVersion);
      return;
    }
    await cmd.run(arguments);
  }
}
