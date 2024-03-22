import 'package:release_tools/utils/license_header_parser.dart';
import 'package:test/test.dart';

const headerTemplate = '''
Copyright (c) [YEAR] The Project Developers.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated files...

What could go wrong if this is not indented properly? I say good day sir have this cookie:

  The quick brown fox
  Jumped over the lazy dog
''';

void main() {
  group(LicenseHeaderParser, () {
    final parser = LicenseHeaderParser(headerTemplate);

    test('apply()', () {
      expect(
        parser.apply(2024, prefix: '// '),
        equals(
          '''
// Copyright (c) 2024 The Project Developers.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated files...
//
// What could go wrong if this is not indented properly? I say good day sir
// have this cookie:
//
//  The quick brown fox
//  Jumped over the lazy dog
''',
        ),
      );
    });

    group('matches()', () {
      test('returns false for empty string', () {
        expect(parser.matches('', year: 2024), isFalse);
      });

      test('returns false for not specified prefix', () {
        expect(
          parser.matches(
            '''
// Copyright (c) 2024 The Project Developers.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated files...
''',
            year: 2024,
          ),
          isFalse,
        );
      });

      test('returns false with correct prefix but for non-matching header', () {
        expect(
          parser.matches(
            '''
// Copyright (c) 2024 The Bad Chump
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated files...
''',
            prefix: '// ',
            year: 2000,
          ),
          isFalse,
        );
      });

      test(
        'returns true for matching header',
        () {
          print("\n MATCHING THING");
          expect(
            parser.matches(
              '''
// Copyright (c) 2024 The Project Developers.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated files...
//
// What could go wrong if this is not indented properly? I say good day sir
// have this cookie:
//
//   The quick brown fox
//   Jumped over the lazy dog
''',
              prefix: '// ',
              year: 2024,
            ),
            isTrue,
          );
        },
      );
    });
  });
}
