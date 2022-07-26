import 'package:file/memory.dart';
import 'package:release_tools/current_version_command.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:test/test.dart';

import 'runner_setup.dart';

void main() {
  group(CurrentVersionCommand, () {
    runnerSetup((getContext) {
      late ReleaseToolsRunner runner;
      late MemoryFileSystem fs;
      late String workingDir;
      late StubPrinter printer;

      const command = 'current_version';

      setUp(() {
        final context = getContext();
        runner = context.runner;
        fs = context.fs;
        workingDir = context.workingDir;
        printer = context.printer;
      });

      group('errors', () {
        test('throws StateError when there is no pubspec.yaml is available',
            () {
          expect(() => runner.run([command]), throwsStateError);
        });

        test(
            'throws StateError when version key is not present on pubspec.yaml',
            () async {
          final pubspecFile =
              fs.directory(workingDir).childFile('pubspec.yaml');
          await pubspecFile.writeAsString('foo: bar');
          expect(() => runner.run([command]), throwsStateError);
        });

        test('throws StateError when pubspec.yaml is not a valid yaml file',
            () async {
          final pubspecFile =
              fs.directory(workingDir).childFile('pubspec.yaml');
          await pubspecFile.writeAsString(' 113241#');
          expect(() => runner.run([command]), throwsStateError);
        });
      });

      group('happy paths', () {
        test('prints the version on pubspec.yaml', () async {
          final pubspecFile =
              fs.directory(workingDir).childFile('pubspec.yaml');
          await pubspecFile.writeAsString(
            '''
name: foo_bar
description: A sample pubspec file._file
version: 2.0.0

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  equatable: ^2.0.0

dev_dependencies:
  test: ^1.14.4
''',
          );
          await runner.run([command]);
          expect(printer.prints.first, equals('2.0.0'));
        });
      });
    });
  });
}
