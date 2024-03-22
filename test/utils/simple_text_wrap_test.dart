import 'package:release_tools/utils/simple_text_wrap.dart';
import 'package:test/test.dart';

void main() {
  group('simpleTextWrap', () {
    test('wraps text', () {
      const text =
          'A very long line of text that needs to be wrapped\n\nA very long line of text that needs to be wrapped';
      final result = simpleTextWrap(text, width: 20).split('\n');
      expect(
        result,
        [
          'A very long line of',
          'text that needs to be',
          'wrapped',
          '',
          'A very long line of',
          'text that needs to be',
          'wrapped',
        ],
      );
    });

    test('wraps text with default 80 width', () {
      const text =
          'A very long line of text that needs to be wrapped. A very long line of text that needs to be wrapped.';
      final result = simpleTextWrap(text).split('\n');
      expect(
        result,
        [
          'A very long line of text that needs to be wrapped. A very long line of text that',
          'needs to be wrapped.',
        ],
      );
    });

    test('wraps text with prefix', () {
      const text = 'A very long line of text that needs to be wrapped';
      final result = simpleTextWrap(text, width: 20, prefix: '# ').split('\n');
      expect(
        result,
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
      final result = simpleTextWrap(text, width: 20, prefix: '# ').split('\n');
      expect(
        result,
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

        final result = simpleTextWrap(text, width: 20).split('\n');
        for (final line in result) {
          expect(
            line.length,
            lessThanOrEqualTo(20),
            reason: '"$line" exceeded 20 characters width specified',
          );
        }
        expect(
          result,
          [
            'A very long line of',
            'text that needs to',
            'be wrapped',
            'and has some more',
            'text that needs to',
            'be wrapped in',
            'another line',
            'with this one again',
          ],
        );
      },
    );

    test(
      'it considers indentations',
      () {
        final text = [
          'When the going gets tough, the tough gets going',
          '  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ac risus id risus dictum blandit. Donec non.',
        ].join('\n');

        final result = simpleTextWrap(text, width: 20).split('\n');
        expect(
          result,
          [
            'When the going gets tough, the tough gets going',
            '  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ac risus id',
            '  risus dictum blandit. Donec non.',
          ],
        );
      },
      skip: true,
    );
  });
}
