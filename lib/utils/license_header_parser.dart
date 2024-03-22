import 'simple_text_wrap.dart';

typedef _VarMap = Map<String, String>;

abstract class _TemplateLinePart {
  final String raw;

  _TemplateLinePart(this.raw);

  @override
  String toString() => raw;
}

class _TemplateWord extends _TemplateLinePart {
  _TemplateWord(super.raw);
}

class _TemplateVariable extends _TemplateLinePart {
  final String name;

  _TemplateVariable(super.raw)
      : name = raw.substring(1, raw.length - 1).toUpperCase();

  // String render(Map<String, String> values) => values[name] ?? '';
  String render(Map<String, String> values) {
    return values[name] ?? '';
  }
}

class _TemplateSpaces extends _TemplateLinePart {
  _TemplateSpaces(super.raw);
}

final searchWords = RegExp(r'(\s*)((\[[A-Z]+\])|(\S+))');
List<_TemplateLinePart> _lineParts(String line) {
  return searchWords
      .allMatches(line)
      .map((match) {
        final List<_TemplateLinePart> prep = [];
        final spaceMatch = match.group(1);
        final wordMatch = match.group(4);
        final varMatch = match.group(3);

        if (spaceMatch is String && spaceMatch.isNotEmpty) {
          prep.add(_TemplateSpaces(spaceMatch));
        }
        if (wordMatch is String) {
          prep.add(_TemplateWord(wordMatch));
        }
        if (varMatch is String) {
          prep.add(_TemplateVariable(varMatch));
        }

        return prep;
      })
      .expand((i) => i)
      .toList();
}

class _TemplateLine {
  final String raw;
  final List<_TemplateLinePart> parts;

  _TemplateLine(this.raw) : parts = _lineParts(raw);

  _TemplateLinePart? partAt(int index) =>
      index < parts.length ? parts[index] : null;

  String render(_VarMap values) {
    return parts.map((part) {
      if (part is _TemplateVariable) {
        return part.render(values);
      }
      return part.raw;
    }).join();
  }

  @override
  String toString() {
    return '[${parts.map((part) => part.toString()).join(', ')}]';
  }
}

class _TemplateResult {
  final String raw;
  final List<_TemplateLine> lines;

  _TemplateResult(String raw)
      : raw = raw.trim(),
        lines = raw
            .trim()
            .split('\n')
            .map(
              (line) => _TemplateLine(line),
            )
            .toList();

  String render(_VarMap values, {String prefix = ''}) {
    return simpleTextWrap(
      lines.map((line) {
        final rendered = line.render(values);
        print('rendered: "$rendered"');
        return rendered;
      }).join('\n'),
      prefix: prefix,
    );
  }

  _TemplateLine? lineAt(int index) =>
      index < lines.length ? lines[index] : null;
}

/// Parse a license header template for matching and applying to files
///
/// License headers are blocks of comments at the top of a file that contain
/// copyright and licensing information. This class is used to parse a license
/// header template and apply it based on some given commenting format.
///
/// An example of a license header template coulb be the following:
///
/// ```
/// Copyright 2024 The Foo Project Developers.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to...
/// ```
class LicenseHeaderParser {
  final String templateContent;
  final _TemplateResult parsed;

  LicenseHeaderParser(this.templateContent)
      : parsed = _TemplateResult(templateContent);

  bool matches(String renderedHeader, {String prefix = '', required int year}) {
    final values = {'YEAR': year.toString()};

    return parsed.render(values, prefix: prefix) == renderedHeader;
  }

  String apply(int year, {String prefix = ''}) {
    final values = {'YEAR': year.toString()};

    return parsed.render(values, prefix: prefix);
  }
}
