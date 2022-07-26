import 'package:args/command_runner.dart';
import 'package:file/file.dart';

import 'changelog_command.dart';
import 'current_version_command.dart';
import 'git_exec.dart';
import 'next_version_command.dart';
import 'prepare_release_command.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_version.dart';
import 'remote_tag_id_command.dart';
import 'should_release_command.dart';
import 'update_version_command.dart';
import 'update_year_command.dart';

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
