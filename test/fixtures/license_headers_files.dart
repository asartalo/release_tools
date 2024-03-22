import 'package:file/file.dart';
import 'package:path/path.dart' as p;

enum LicenseHeadersTestFixtures {
  template(
    'tool/LICENSE_HEADER_TEMPLATE',
    '''
Copyright [YEAR] The Foo Project Developers.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software blah blah blah:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, YADA YADA YADA.
''',
  ),
  noHeaderDart(
    'lib/src/no_header.dart',
    'main() => print("Hello, World!");',
  ),
  withHeaderDart(
    'lib/src/with_header.dart',
    '''
// Copyright 2019 The Foo Project Developers.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software blah blah blah:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// YADA YADA YADA.
main() => print("Boo!");
''',
  ),
  noHeaderHtml(
    'static/index_no_header.html',
    '<html><body>Hello, World!</body></html>',
  );

  const LicenseHeadersTestFixtures(this.path, this.originalContent);

  final String path;
  final String originalContent;

  String get pathDir => p.dirname(path);
  String get fileName => p.basename(path);

  Future<File> writeFixtureFile({
    String? content,
    required FileSystem fs,
    required String workingDir,
  }) async {
    final directory = await fs
        .directory(
          p.join(workingDir, pathDir),
        )
        .create(recursive: true);
    final file = directory.childFile(fileName);
    await file.writeAsString(content ?? originalContent);
    return file;
  }

  Future<String> getFixtureFileContents({
    required FileSystem fs,
    required String workingDir,
  }) async {
    final file = fs.file(
      fs.directory(p.join(workingDir, pathDir)).childFile(fileName),
    );
    return file.readAsString();
  }
}
