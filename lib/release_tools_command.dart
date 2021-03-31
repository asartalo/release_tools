import 'package:args/command_runner.dart';
import 'package:release_tools/printer.dart';

abstract class ReleaseToolsCommand extends Command {
  Printer get printer;

  @override
  void printUsage() => printer.println(usage);
}
