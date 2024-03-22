import 'simple_text_wrap.dart';

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

  LicenseHeaderParser(String templateContent)
      : templateContent = templateContent.trim();

  bool matches(String renderedHeader, {String prefix = '', required int year}) {
    return apply(year, prefix: prefix) == renderedHeader.trim();
  }

  String apply(int year, {String prefix = ''}) {
    return simpleTextWrap(
      templateContent.trim().replaceAll('[YEAR]', year.toString()),
      prefix: prefix,
    );
  }
}
