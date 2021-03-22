import 'dart:io';

import 'package:release_tools/printer.dart';
import 'package:test/test.dart';

void main() {
  group(TruePrinter, () {
    late TruePrinter printer;
    late _FakeStdout fakeStdout;
    late _FakeStdout fakeStderr;

    setUp(() {
      fakeStdout = _FakeStdout();
      fakeStderr = _FakeStdout();
      printer = TruePrinter(stdout: fakeStdout, stderr: fakeStderr);
    });

    group('println()', () {
      test('it prints to stdout', () async {
        printer.println('Hello');
        expect(fakeStdout.prints.last, equals('Hello'));
      });
    });

    group('printErr()', () {
      test('it prints to stderr in red', () async {
        printer.printErr('Boo');
        expect(fakeStderr.prints.last, equals(red('Boo')));
      });
    });

    group('printSuccess()', () {
      test('it prints to stdout in green', () async {
        printer.printSuccess('Boo');
        expect(fakeStdout.prints.last, equals(green('Boo')));
      });
    });
  });
}

/// This class is for stubbing stdout only
class _FakeStdout implements Stdout {
  final List<String> prints = [];

  @override
  void writeln([Object? object = ""]) {
    prints.add('$object');
  }

  @override
  // ignore: always_declare_return_types, type_annotate_public_apis
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
