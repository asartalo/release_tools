import 'package:ansicolor/ansicolor.dart';

abstract class Printer {
  /// Prints a regular string
  external void println(String str);

  /// Prints an error string
  external void printErr(String str);
}

/// A wrapper for executing print() statements
class TruePrinter implements Printer {
  @override
  void println(String str) {
    print(str);
  }

  @override
  void printErr(String str) {
    final pen = AnsiPen()..red();
    print(pen(str));
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
}
