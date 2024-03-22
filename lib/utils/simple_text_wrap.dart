// TODO: Refactor this with a better implementation
String _wrapParagraph(String paragraph, {int width = 80, String prefix = ''}) {
  final length = width - prefix.length;
  final inputLines = paragraph.split('\n');
  final lines = StringBuffer();
  final indentCheck = RegExp(r'^(\s+)(\S.+)');

  for (final inputLine in inputLines) {
    final match = indentCheck.firstMatch(inputLine);
    String indentation = '';
    late List<String> words;

    if (match != null) {
      indentation = match.group(1) ?? '';
      words = match.group(2)?.split(' ') ?? [];
    } else {
      words = inputLine.split(' ');
    }
    var line = StringBuffer();
    line.write(indentation);

    for (final word in words) {
      final lineLengthWhenWordIsAdded =
          prefix.length + line.length + 1 + word.length;
      if (lineLengthWhenWordIsAdded > length) {
        lines.write('$prefix$line\n');
        line = StringBuffer();
        line.write(indentation);
      }
      line.write(line.length == indentation.length ? word : ' $word');
    }
    lines.write('$prefix$line\n');
  }

  return lines.toString().trimRight();
}

String simpleTextWrap(String text, {int width = 80, String prefix = ''}) {
  final all = StringBuffer();
  final paragraphs = text.split('\n\n');

  for (final paragraph in paragraphs) {
    final wrapped = _wrapParagraph(paragraph, width: width, prefix: prefix);
    all.write(all.isNotEmpty ? '\n${prefix.trimRight()}\n$wrapped' : wrapped);
  }

  return all.toString();
}
