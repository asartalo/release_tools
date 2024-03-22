import 'package:release_tools/utils/simple_text_wrap.dart';
import 'package:test/test.dart';

void main() {
  group('simpleTextWrap', () {
    void expectWrapped(String text, int width, List<String> expected) {
      final result = text.split('\n');

      for (final line in expected) {
        expect(
          line.length,
          lessThanOrEqualTo(width),
          reason: 'Line in expected input "$line" with length of '
              '${line.length} is greater than specified width $width',
        );
      }

      for (final line in result) {
        expect(
          line.length,
          lessThanOrEqualTo(width),
          reason: 'Line in actual result "$line" with length of ' +
              '${line.length} is greater than specified width $width',
        );
      }
      expect(result, expected);
    }

    test('wraps text', () {
      const text =
          'A very long line of text that needs to be wrapped\n\nA very long line of text that needs to be wrapped';
      final result = simpleTextWrap(text, width: 20);

      expectWrapped(result, 20, [
        'A very long line of',
        'text that needs to',
        'be wrapped',
        '',
        'A very long line of',
        'text that needs to',
        'be wrapped',
      ]);
    });

    test('wraps text with default 80 width', () {
      const text =
          'A very long line of text that needs to be wrapped. A very long line of text that needs to be wrapped.';
      final result = simpleTextWrap(text);

      expectWrapped(
        result,
        80,
        [
          'A very long line of text that needs to be wrapped. A very long line of text that',
          'needs to be wrapped.',
        ],
      );
    });

    test('wraps text with prefix', () {
      const text = 'A very long line of text that needs to be wrapped';
      final result = simpleTextWrap(text, width: 20, prefix: '# ');

      expectWrapped(
        result,
        20,
        [
          '# A very long line',
          '# of text that',
          '# needs to be',
          '# wrapped',
        ],
      );
    });

    test('prefixes blank lines', () {
      const text =
          'A very long line of text that needs to be wrapped\n\nA very long line of text that needs to be wrapped';
      final result = simpleTextWrap(text, width: 20, prefix: '# ');
      expectWrapped(
        result,
        20,
        [
          '# A very long line',
          '# of text that',
          '# needs to be',
          '# wrapped',
          '#',
          '# A very long line',
          '# of text that',
          '# needs to be',
          '# wrapped',
        ],
      );
    });

    test(
      'it rewraps text with newlines',
      () {
        final text = [
          'A very long line of text that needs to be wrapped',
          'and has some more text that needs to be wrapped in another line',
          'with this one again',
        ].join('\n');

        final result = simpleTextWrap(text, width: 20);

        expectWrapped(result, 20, [
          'A very long line of',
          'text that needs to',
          'be wrapped',
          'and has some more',
          'text that needs to',
          'be wrapped in',
          'another line',
          'with this one again',
        ]);
      },
    );

    test(
      'it respects indentations',
      () {
        final text = [
          'When the going gets tough, the tough gets going along. And along.',
          '  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ac risus id risus dictum blandit. Donec non.',
        ].join('\n');

        final result = simpleTextWrap(text, width: 60);
        expectWrapped(
          result,
          60,
          [
            'When the going gets tough, the tough gets going along. And',
            'along.',
            '  Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            '  Sed ac risus id risus dictum blandit. Donec non.',
          ],
        );
      },
    );
  });
}
