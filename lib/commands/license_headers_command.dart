import 'package:file/file.dart';

import '../printer.dart';
import '../project.dart';
import '../utils/simple_text_wrap.dart';
import 'release_tools_command.dart';

const _defaultTemplatePath = 'tool/LICENSE_HEADER_TEMPLATE';

class LicenseHeadersCommand extends ReleaseToolsCommand {
  final Project project;
  final DateTime now;

  @override
  final Printer printer;

  @override
  final name = 'license_headers';

  @override
  final description =
      'Updates license header on file. Defaults to license files';

  @override
  final invocation = 'release_tools license_header';

  @override
  final takesArguments = true;

  @override
  final usageFooter = '''
release_tools license_header
release_tools license_header --template=MY_LICENSE_TEMPLATE_FILE.txt
''';

  LicenseHeadersCommand({
    required this.project,
    required this.printer,
    required this.now,
  }) {
    argParser.addOption(
      'template',
      help: 'specify a file to use as template',
      abbr: 't',
    );
  }

  @override
  Future<void> run() async {
    final args = ensureArgResults();
    final templateArg = args['template'] as String?;
    final template = templateArg ?? _defaultTemplatePath;
    final file = project.getFile(template);
    if (!await file.exists()) {
      throw StateError('Unable to find template file "$template".');
    }

    await _applyTemplateToFiles(file);
  }

  Future<void> _applyTemplateToFiles(File template) async {
    final files = await project.getFiles();
    final templateContent = await template.readAsString();
    for (final file in files) {
      await _applyTemplateToFile(templateContent, file);
    }
  }

  Future<void> _applyTemplateToFile(String templateContent, File file) async {
    final fileContent = await file.readAsString();

    if (_hasHeader(fileContent, templateContent)) {
      return;
    }

    final toPrepend = _commentAndWrap(templateContent);
    await file.writeAsString(
      '$toPrepend\n\n$fileContent',
    );
  }

  String _commentAndWrap(String templateContent) {
    return simpleTextWrap(
      templateContent.replaceAll('[YEAR]', now.year.toString()),
      prefix: "// ",
    );
  }

  bool _hasHeader(String fileContent, String templateContent) {
    final header = _commentAndWrap(templateContent);
    return fileContent.startsWith(header);
  }
}
