import 'dart:io';

import 'package:ansicolor/ansicolor.dart';

abstract class Printer {
  /// Prints a regular string
  external void println(String str);

  /// Prints a string signifying success.
  external void printSuccess(String str);

  /// Prints an error string
  external void printErr(String str);
}

final red = AnsiPen()..red();
final green = AnsiPen()..green();

/// A wrapper for executing print() statements
class TruePrinter implements Printer {
  late Stdout stdout;
  late Stdout stderr;

  TruePrinter({
    required this.stdout,
    required this.stderr,
  });

  @override
  void println(String str) {
    stdout.writeln(str);
  }

  @override
  void printErr(String str) {
    stderr.writeln(red(str));
  }

  @override
  void printSuccess(String str) {
    stdout.writeln(green(str));
  }
}

/// Use StubPrinter to substitute for TruePrinter when running tests. All
/// printed values will be stored.
///
/// For [println], it can be accessed through [prints].
///
/// For [printErr], it can be accessed through [errorPrints].
class StubPrinter implements Printer {
  final List<String> prints = [];
  final List<String> errorPrints = [];

  @override
  void println(String str) {
    prints.add(str);
  }

  @override
  void printErr(String str) {
    errorPrints.add(str);
  }

  @override
  void printSuccess(String str) {
    prints.add(str);
  }
}
