import 'package:file/memory.dart';
import 'package:release_tools/commands/license_headers_command.dart';
// import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:test/test.dart';

import '../fixtures/license_headers_files.dart';
import '../runner_setup.dart';

typedef TestFile = LicenseHeadersTestFixtures;

void main() {
  group(LicenseHeadersCommand, () {
    final now = DateTime.parse('2021-02-10');

    runnerSetup((getContext) {
      late ReleaseToolsRunner runner;
      late MemoryFileSystem fs;
      late String workingDir;
      // late StubPrinter printer;
      const command = 'license_headers';

      setUp(() async {
        final context = getContext(now: now);
        runner = context.runner;
        fs = context.fs;
        workingDir = context.workingDir;
        // printer = context.printer;
      });
      group('errors', () {
        test(
          'throws StateError when default template file does not exist and no specified template file to use',
          () {
            expect(
              () => runner.run([command]),
              throwsStateError,
            );
          },
        );

        test(
          'throws StateError when specified template file does not exist',
          () {
            expect(
              () => runner.run([command, '--template', 'MY_TEMPLATE']),
              throwsStateError,
            );
          },
        );
      });

      group('happy paths', () {
        setUp(() async {
          final files = [
            TestFile.template,
            TestFile.withHeaderDart,
            TestFile.noHeaderDart,
          ];
          for (final file in files) {
            file.writeFixtureFile(fs: fs, workingDir: workingDir);
          }
        });

        test('it updates license header on license file', () async {
          await runner.run([command]);
          final contents = await TestFile.noHeaderDart
              .getFixtureFileContents(fs: fs, workingDir: workingDir);
          expect(
            contents,
            contains('// Copyright ${now.year} The Foo Project Developers'),
          );
        });

        test(
          'it does not update license header on file with existing header',
          () async {
            await runner.run([command]);
            const withHeader = TestFile.withHeaderDart;
            final contents = await withHeader.getFixtureFileContents(
              fs: fs,
              workingDir: workingDir,
            );
            expect(contents, equals(withHeader.originalContent));
          },
        );
      });
    });
  }, skip: true);
}
