import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:release_tools/printer.dart';
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

      Future<void> validYamlFile() async {
        final file = fs.directory(workingDir).childFile('pubspec.yaml');
        await file.writeAsString(kValidPubspecFile);
      }

      Future<File> getPubFile() async {
        return fs.file(fs.directory(workingDir).childFile('pubspec.yaml'));
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
