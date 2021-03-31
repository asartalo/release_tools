String helpFooter(String example) {
  return '''

Example:
${_printExamples(example)}

See https://pub.dev/packages/release_tools for more information.''';
}

String _printExamples(String example) {
  return example.split('\n').map((part) => '  $part').join('\n');
}
