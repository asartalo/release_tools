import 'package:file/file.dart';

import 'help_footer.dart';
import 'printer.dart';
import 'project.dart';
import 'release_tools_command.dart';

final _yearRegexp = RegExp(r'(\d{4,}(, |-))*(\d{4,})');
const defaultLicenseFiles = ['LICENSE', 'LICENSE.txt'];

class _ReplaceResult {
  final String content;
  final String yearPhrase;

  _ReplaceResult(this.content, this.yearPhrase);
}

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
    final args = ensureArgResults();
    final fileArg = args['file'];
    final licenseArg = args['license'];
    final specificFile = fileArg is String
        ? fileArg
        : licenseArg is String
            ? licenseArg
            : null;

    await updateYearOnFile(specificFile);
  }

  Future<void> updateYearOnFile(String? specificFile) async {
    final file = specificFile is String
        ? await _findLicenseFile(specificFile)
        : await _findDefaultLicenseFiles();
    final contents = await file.readAsString();
    if (!_yearIsUpdated(contents)) {
      final replacement = _replaceYear(contents);
      await file.writeAsString(replacement.content);
      printer.printSuccess(
        'Year on ${file.basename} file has been updated to "${replacement.yearPhrase}".',
      );
    } else {
      printer.println('Year on ${file.basename} file is already updated.');
    }
  }

  _ReplaceResult _replaceYear(String content) {
    final year = now.year;
    final match = _yearRegexp.firstMatch(content);
    String replacedContent = content;
    String replacedYear = year.toString();

    if (match is RegExpMatch) {
      final yrStr = match.group(3)!;
      final yearOnFile = int.parse(yrStr);
      // print("\n\n===\nyearOnFile: $yearOnFile year: $year");
      if (yearOnFile + 1 == year) {
        final delimeter = match.group(2);
        if (delimeter == '-') {
          replacedYear = '$year';
        } else {
          replacedYear = '$yrStr-$year';
        }
      } else if (yearOnFile + 1 < year) {
        replacedYear = '$yrStr, $year';
      }
      replacedContent = content.replaceFirst(yrStr, replacedYear);
    }
    return _ReplaceResult(replacedContent, replacedYear);
  }

  bool _yearIsUpdated(String content) {
    final match = _yearRegexp.firstMatch(content);
    if (match is RegExpMatch) {
      return now.year.toString() == match.group(3);
    }
    return false;
  }

  Future<File> _findDefaultLicenseFiles() async {
    late File file;
    bool found = false;
    for (final fileName in defaultLicenseFiles) {
      file = project.getFile(fileName);
      if (await file.exists()) {
        found = true;
        break;
      }
    }
    if (!found) {
      final validFiles = defaultLicenseFiles.map((str) => '"$str"').join(', ');
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
