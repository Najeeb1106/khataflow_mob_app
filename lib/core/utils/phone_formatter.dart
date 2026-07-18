import 'phone_normalizer.dart';

/// Reusable utility for formatting phone numbers for display purposes only.
class PhoneFormatter {
  PhoneFormatter._();

  /// Formats a phone number for display.
  ///
  /// If the normalized phone number contains exactly 10 digits, it displays it as:
  ///   0XXX XXXXXXX
  /// E.g. '3467266586' -> '0346 7266586'
  ///
  /// If formatting is not possible, it gracefully falls back to the original value.
  static String format(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';

    final normalized = PhoneNormalizer.normalize(phone);
    if (normalized.length == 10) {
      final prefix = normalized.substring(0, 3);
      final suffix = normalized.substring(3);
      return '0$prefix $suffix';
    }

    return phone;
  }
}
