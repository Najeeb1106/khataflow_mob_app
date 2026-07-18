import 'package:flutter_test/flutter_test.dart';
import 'package:khata_app/core/utils/phone_formatter.dart';

void main() {
  group('PhoneFormatter Tests', () {
    test('returns empty string for null input', () {
      expect(PhoneFormatter.format(null), '');
    });

    test('returns empty string for empty input', () {
      expect(PhoneFormatter.format(''), '');
      expect(PhoneFormatter.format('   '), '');
    });

    test('formats 10-digit normalized phone number correctly', () {
      expect(PhoneFormatter.format('3467266586'), '0346 7266586');
    });

    test('normalizes input before checking length', () {
      expect(PhoneFormatter.format('+923467266586'), '0346 7266586');
      expect(PhoneFormatter.format('923467266586'), '0346 7266586');
      expect(PhoneFormatter.format('03467266586'), '0346 7266586');
      expect(PhoneFormatter.format('0346 726-6586'), '0346 7266586');
    });

    test('gracefully falls back to original input for non-10-digit numbers', () {
      expect(PhoneFormatter.format('12345'), '12345');
      expect(PhoneFormatter.format('034672665861'), '034672665861');
      expect(PhoneFormatter.format('abc'), 'abc');
    });
  });
}
