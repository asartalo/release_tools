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
      const originalLicenseContent = '''
Copyright 2020 Jane Doe

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';
      const expectedContent = '''
Copyright 2021 Jane Doe

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''';

      setUp(() async {
        final context = getContext(now: now);
        runner = context.runner;
        fs = context.fs;
        workingDir = context.workingDir;
        printer = context.printer;
      });

      Future<String> getLicenseFileContents(
          [String fileName = 'LICENSE']) async {
        final file = fs.file(fs.directory(workingDir).childFile(fileName));
        return file.readAsString();
      }

      Future<File> writeLicenseContent(
          [String fileName = 'LICENSE',
          String content = originalLicenseContent]) async {
        final file = fs.directory(workingDir).childFile(fileName);
        await file.writeAsString(content);
        return file;
      }

      group('errors', () {
        test('throws StateError when no LICENSE file exists', () {
          expect(() => runner.run([command]), throwsStateError);
        });

        test('throws StateError when no specified license file exists', () {
          expect(() => runner.run([command, '--license', 'MY_LICENSE']),
              throwsStateError);
        });
      });

      group('happy paths', () {
        test('it updates year on license file', () async {
          await writeLicenseContent();
          await runner.run([command]);
          expect(await getLicenseFileContents(), equals(expectedContent));
        });

        test('it prints a success message', () async {
          await writeLicenseContent();
          await runner.run([command]);
          expect(
            printer.prints.last,
            equals('Year on LICENSE file has been updated to ${now.year}'),
          );
        });

        test('it updates year on license file named "LICENSE.txt"', () async {
          await writeLicenseContent('LICENSE.txt');
          await runner.run([command]);
          expect(await getLicenseFileContents('LICENSE.txt'),
              equals(expectedContent));
        });

        test('it updates year on license file specified', () async {
          await writeLicenseContent('MY_LICENSE');
          await runner.run([command, '--license', 'MY_LICENSE']);
          expect(await getLicenseFileContents('MY_LICENSE'),
              equals(expectedContent));
        });

        group('if year is already updated', () {
          late File file;
          late DateTime modified;

          setUp(() async {
            file = await writeLicenseContent('LICENSE', expectedContent);
            modified = file.statSync().modified;
            await runner.run([command]);
          });

          test('it leaves content the same', () async {
            expect(await getLicenseFileContents(), equals(expectedContent));
          });

          test('it does not change file', () async {
            final modifiedAfter = file.statSync().modified;
            expect(modifiedAfter, equals(modified));
          });

          test('it prints a friendly message', () {
            expect(printer.prints.last, equals('File is already updated.'));
          });
        });

        test('it prints help text', () async {
          await runner.run([command, '--help']);
          final helpText = printer.prints.join('\n');
          expect(
            helpText,
            contains('Updates year on license file.'),
          );
          expect(helpText, contains('Usage:'));
        });
      });
    });
  });
}
