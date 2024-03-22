String _wrapParagraph(String paragraph, {int width = 80, String prefix = ''}) {
  final lines = StringBuffer();
  final words = paragraph.split(' ');
  final length = width - prefix.length;

  var line = StringBuffer();
  for (final word in words) {
    if ((prefix.length + line.length + 1 + word.length) > length) {
      lines.write('$prefix$line\n');
      line = StringBuffer();
    }
    line.write(line.isNotEmpty ? ' $word' : word);
  }
  lines.write(prefix + line.toString());

  return lines.toString();
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
