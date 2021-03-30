import 'package:file/local.dart';
import 'package:release_tools/exec.dart';
import 'package:test/test.dart';

void main() {
  group(Exec, () {
    late Exec exec;
    late Execution result;

    setUp(() {
      const fs = LocalFileSystem();
      exec = Exec(workingDir: fs.currentDirectory.path);
    });

    group('successfull shell command', () {
      setUp(() async {
        result = await exec.execute('echo', ['hello']);
      });

      test('it is successful', () {
        expect(result.success, equals(true));
      });

      test('it returns output', () {
        expect(result.output, equals('hello'));
      });
    });

    group('unsuccessful shell command', () {
      setUp(() async {
        result = await exec.execute('foobar', ['--badoption']);
      });

      test('it is not successful', () {
        expect(result.success, equals(false));
      });
      test('it prints out errors too', () {
        expect(result.output, contains('foobar'));
      });
    });
  });
}
