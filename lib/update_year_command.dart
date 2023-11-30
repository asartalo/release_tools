import 'package:file/file.dart';

import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';

final _yearRegexp = RegExp(r'\d{4}');
const _defaultLicenseFiles = ['LICENSE', 'LICENSE.txt'];

class UpdateYearCommand extends ReleaseToolsCommand {
  final Project project;
  final DateTime now;

  @override
  final Printer printer;

  @override
  final name = 'update_year';

  @override
  final description = 'Updates year on file. Defaults to license files';

  @override
  final invocation = 'release_tools update_year';

  @override
  final takesArguments = true;

  @override
  final usageFooter = helpFooter(
    '''
release_tools update_year
release_tools update_year --file=MY_LICENSE_FILE
''',
  );

  UpdateYearCommand({
    required this.project,
    required this.printer,
    required this.now,
  }) {
    argParser.addOption(
      'license',
      help: 'specify a file to update',
      abbr: 'l',
    );
    argParser.addOption(
      'file',
      help: 'specify a file to update',
      abbr: 'f',
    );
  }

  @override
  Future<void> run() async {
    final year = now.year;
    final args = ensureArgResults();
    final specificFile =
        args['file'] is String ? args['file'] : args['license'];

    final file = specificFile is String
        ? await _findLicenseFile(specificFile)
        : await _findDefaultLicenseFiles();
    final contents = await file.readAsString();
    if (!_yearIsUpdated(contents)) {
      await file
          .writeAsString(contents.replaceFirst(_yearRegexp, year.toString()));
      printer.printSuccess(
        'Year on ${file.basename} file has been updated to $year',
      );
    } else {
      printer.println('File is already updated.');
    }
  }

  bool _yearIsUpdated(String content) {
    final match = _yearRegexp.firstMatch(content);
    if (match is RegExpMatch) {
      return now.year.toString() == match.group(0);
    }
    return false;
  }

  Future<File> _findDefaultLicenseFiles() async {
    late File file;
    bool found = false;
    for (final fileName in _defaultLicenseFiles) {
      file = project.getFile(fileName);
      if (await file.exists()) {
        found = true;
        break;
      }
    }
    if (!found) {
      final validFiles = _defaultLicenseFiles.map((str) => '"$str"').join(', ');
      throw StateError(
        'Unable to find a license file. Was looking for $validFiles',
      );
    }
    return file;
  }

  Future<File> _findLicenseFile(String name) async {
    final file = project.getFile(name);
    if (!await file.exists()) {
      throw StateError('Unable to find a license file "$name".');
    }
    return file;
  }
}
