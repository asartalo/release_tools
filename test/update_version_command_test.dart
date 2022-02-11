import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:release_tools/update_version_command.dart';
import 'package:test/test.dart';
import 'runner_setup.dart';

void main() {
  group(UpdateVersionCommand, () {
    runnerSetup((getContext) {
      late ReleaseToolsRunner runner;
      late MemoryFileSystem fs;
      late String workingDir;
      late StubPrinter printer;

      setUp(() {
        final context = getContext();
        runner = context.runner;
        fs = context.fs;
        workingDir = context.workingDir;
        printer = context.printer;
      });

      Future<void> writeFile(String fileName, String contents) async {
        final file = fs.directory(workingDir).childFile(fileName);
        await file.writeAsString(contents);
      }

      Future<void> validYamlFile() async {
        await writeFile('pubspec.yaml', kValidPubspecFile);
      }

      Future<String> getFileContents(String fileName) async {
        return fs
            .file(fs.directory(workingDir).childFile(fileName))
            .readAsString();
      }

      Future<File> getFile(String fileName) async {
        return fs.file(fs.directory(workingDir).childFile(fileName));
      }

      Future<File> getPubFile() async {
        return getFile('pubspec.yaml');
      }

      group('errors', () {
        test('throws MissingPubspecError when there is no pubspec.yaml',
            () async {
          expect(
            () => runner.run(['update_version', '2.0.0']),
            throwsA(const TypeMatcher<MissingPubspecError>()),
          );
        });

        group('when there is a pubspec file', () {
          setUp(() async {
            await validYamlFile();
          });

          test('throws ArgumentError when no version is provided', () async {
            expect(
              () => runner.run(['update_version']),
              throwsA(const TypeMatcher<ArgumentError>()),
            );
          });
        });
      });

      group('writes version', () {
        setUp(() async {
          await validYamlFile();
          await runner.run(['update_version', '1.0.0']);
        });

        test('updates pubspec.yaml', () async {
          final pubFile = await getPubFile();
          expect(await pubFile.readAsString(), equals('''
name: foo_bar
description: A sample pubspec file._file
version: 1.0.0

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  equatable: ^2.0.0

dev_dependencies:
  test: ^1.14.4
'''));
        });

        test('it shows updated message', () {
          expect(printer.prints.last, equals('Updated version to "1.0.0".'));
        });
      });

      group('updates a version to a specified file', () {
        setUp(() async {
          await writeFile('README.md', '''
Hello.
This is version 1.0.0. Everything is awesome.
''');
          await runner.run([
            'update_version',
            "--template=This is version [VERSION].",
            '--file=README.md',
            '2.0.0',
          ]);
        });

        test('it updates the version in file', () async {
          final contents = await getFileContents('README.md');
          expect(contents, equals('''
Hello.
This is version 2.0.0. Everything is awesome.
'''));
        });
      });

      group('when template and file are set', () {
        const newVersion = '2.0.0';
        final testData = {
          'with just prefix': TemplateTest(
            contents: 'Hello.\nThis is version 1.0.0.\nEverything is awesome.',
            template: 'version [VERSION]',
            expectedResults:
                'Hello.\nThis is version $newVersion.\nEverything is awesome.',
          ),
          'when template just [VERSION]': TemplateTest(
            contents: 'Hello.\nThis is version 1.0.0.\nEverything is awesome.',
            template: '[VERSION]',
            expectedResults:
                'Hello.\nThis is version $newVersion.\nEverything is awesome.',
          ),
          'When template is empty': TemplateTest(
            contents: 'Hello.\nThis is version 1.0.0.\nEverything is awesome.',
            template: '',
            expectedResults:
                'Hello.\nThis is version $newVersion.\nEverything is awesome.',
          ),
          'When version is not specified': TemplateTest(
            contents: 'Hello.\nThis is version 1.0.0.\nEverything is awesome.',
            template: 'This is versino .',
            expectedResults:
                'Hello.\nThis is version 1.0.0.\nEverything is awesome.',
          ),
        };

        testData.forEach((description, data) {
          group(description, () {
            setUp(() async {
              await writeFile('README.md', data.contents);
              await runner.run([
                'update_version',
                "--template=${data.template}",
                '--file=README.md',
                newVersion,
              ]);
            });

            test('it updates the version in file correctly', () async {
              final contents = await getFileContents('README.md');
              expect(contents, equals(data.expectedResults));
            });
          });
        });
      });

      test('it prints help text', () async {
        await runner.run(['update_version', '--help']);
        final helpText = printer.prints.join('\n');
        expect(
          helpText,
          contains('Updates the version number on a pubspec.yaml file.'),
        );
        expect(helpText, contains('Usage:'));
      });
    });
  });
}

class TemplateTest {
  final String template;
  final String contents;
  final String expectedResults;

  TemplateTest({
    required this.template,
    required this.contents,
    required this.expectedResults,
  });
}

const kValidPubspecFile = '''
name: foo_bar
description: A sample pubspec file._file
version: 0.1.0

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  equatable: ^2.0.0

dev_dependencies:
  test: ^1.14.4
''';
