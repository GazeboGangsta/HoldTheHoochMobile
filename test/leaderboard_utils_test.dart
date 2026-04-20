import 'package:flutter_test/flutter_test.dart';
import 'package:hold_the_hooch/utils/format_score.dart';

void main() {
  group('formatScore', () {
    test('formats zero as "0"', () {
      expect(formatScore(0), '0');
    });

    test('formats sub-thousand values with no separators', () {
      expect(formatScore(7), '7');
      expect(formatScore(42), '42');
      expect(formatScore(999), '999');
    });

    test('inserts commas every three digits', () {
      expect(formatScore(1000), '1,000');
      expect(formatScore(12345), '12,345');
      expect(formatScore(1234567), '1,234,567');
    });

    test('handles negative values by preserving the sign', () {
      expect(formatScore(-1234), '-1,234');
    });
  });
}
