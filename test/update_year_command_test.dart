import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:release_tools/printer.dart';
import 'package:release_tools/release_tools_runner.dart';
import 'package:release_tools/update_year_command.dart';
import 'package:test/test.dart';

import 'runner_setup.dart';

void main() {
  group(UpdateYearCommand, () {
    final now = DateTime.parse('2021-02-10');
    runnerSetup((getContext) {
      late ReleaseToolsRunner runner;
      late MemoryFileSystem fs;
      late String workingDir;
      late StubPrinter printer;
      const command = 'update_year';
      const licenseTemplate = '''
Copyright [YEAR] Jane Doe

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';

      setUp(() async {
        final context = getContext(now: now);
        runner = context.runner;
        fs = context.fs;
        workingDir = context.workingDir;
        printer = context.printer;
      });

      Future<String> getLicenseFileContents([
        String fileName = 'LICENSE',
      ]) async {
        final file = fs.file(fs.directory(workingDir).childFile(fileName));
        return file.readAsString();
      }

      String expectedContentYear(String content, String year) {
        return content.replaceFirst('[YEAR]', year);
      }

      Future<File> writeLicenseContent({
        String fileName = 'LICENSE',
        String content = licenseTemplate,
        required String year,
      }) async {
        final file = fs.directory(workingDir).childFile(fileName);
        await file.writeAsString(
          expectedContentYear(content, year),
        );
        return file;
      }

      group('errors', () {
        test('throws StateError when no LICENSE file exists', () {
          expect(() => runner.run([command]), throwsStateError);
        });

        test('throws StateError when no specified license file exists', () {
          expect(
            () => runner.run([command, '--license', 'MY_LICENSE']),
            throwsStateError,
          );
        });

        test('throws StateError when no specified file exists', () {
          expect(
            () => runner.run([command, '--file', 'MY_FILE']),
            throwsStateError,
          );
        });
      });

      group('happy paths', () {
        test('it updates year on license file', () async {
          await writeLicenseContent(year: '2020');
          await runner.run([command]);
          expect(
            await getLicenseFileContents(),
            equals(expectedContentYear(licenseTemplate, '2020-2021')),
          );
        });

        test('it prints a success message', () async {
          await writeLicenseContent(year: '2020');
          await runner.run([command]);
          expect(
            printer.prints.last,
            equals('Year on LICENSE file has been updated to "2020-2021".'),
          );
        });

        test('it updates year on license file named "LICENSE.txt"', () async {
          await writeLicenseContent(fileName: 'LICENSE.txt', year: '2020');
          await runner.run([command]);
          expect(
            await getLicenseFileContents('LICENSE.txt'),
            equals(expectedContentYear(licenseTemplate, '2020-2021')),
          );
        });

        test('it updates year on license file specified', () async {
          await writeLicenseContent(fileName: 'MY_LICENSE', year: '2020');
          await runner.run([command, '--license', 'MY_LICENSE']);
          expect(
            await getLicenseFileContents('MY_LICENSE'),
            equals(expectedContentYear(licenseTemplate, '2020-2021')),
          );
        });

        test('it updates year on file specified', () async {
          await writeLicenseContent(fileName: 'MY_LICENSE', year: '2020');
          await runner.run([command, '--file', 'MY_LICENSE']);
          expect(
            await getLicenseFileContents('MY_LICENSE'),
            equals(expectedContentYear(licenseTemplate, '2020-2021')),
          );
        });

        group('if year is already updated', () {
          late File file;
          late DateTime modified;
          late String expectedContent;

          setUp(() async {
            expectedContent = expectedContentYear(licenseTemplate, '2020-2021');
            file = await writeLicenseContent(
              year: '2020-2021',
              content: expectedContentYear(licenseTemplate, '2020-2021'),
            );
            modified = file.statSync().modified;
            await runner.run([command]);
          });

          test('it leaves content the same', () async {
            expect(await getLicenseFileContents(), expectedContent);
          });

          test('it does not change file', () async {
            final modifiedAfter = file.statSync().modified;
            expect(modifiedAfter, equals(modified));
          });

          test('it prints a friendly message', () {
            expect(printer.prints.last, contains('is already updated.'));
          });
        });

        group('if current year is more than one year ahead', () {
          setUp(() async {
            await writeLicenseContent(year: '2019');
            await runner.run([command]);
          });

          test('it updates year', () async {
            expect(
              await getLicenseFileContents(),
              expectedContentYear(licenseTemplate, '2019, 2021'),
            );
          });

          test('it prints a friendly message', () {
            expect(printer.prints.last, contains('has been updated'));
          });
        });

        group('year on file is complex dashes at the end', () {
          setUp(() async {
            await writeLicenseContent(year: '2017, 2018-2020');
            await runner.run([command]);
          });

          test('it updates year', () async {
            expect(
              await getLicenseFileContents(),
              expectedContentYear(licenseTemplate, '2017, 2018-2021'),
            );
          });
        });

        group("year on file is previous year complex comma'd at the end", () {
          setUp(() async {
            await writeLicenseContent(year: '2017, 2020');
            await runner.run([command]);
          });

          test('it updates year', () async {
            expect(
              await getLicenseFileContents(),
              expectedContentYear(licenseTemplate, '2017, 2020-2021'),
            );
          });
        });

        group("year on file is more than a year ago complex comma'd at the end",
            () {
          setUp(() async {
            await writeLicenseContent(year: '2017, 2019');
            await runner.run([command]);
          });

          test('it updates year', () async {
            expect(
              await getLicenseFileContents(),
              expectedContentYear(licenseTemplate, '2017, 2019, 2021'),
            );
          });
        });

        group("year on is flanked by numbers", () {
          setUp(() async {
            await writeLicenseContent(year: '2019', content: '10 [YEAR] 20');
            await runner.run([command]);
          });

          test('it updates year', () async {
            expect(
              await getLicenseFileContents(),
              expectedContentYear('10 [YEAR] 20', '2019, 2021'),
            );
          });
        });

        test('it prints help text', () async {
          await runner.run([command, '--help']);
          final helpText = printer.prints.join('\n');
          expect(
            helpText,
            contains('Updates year on file.'),
          );
          expect(helpText, contains('Usage:'));
        });
      });
    });
  });
}
