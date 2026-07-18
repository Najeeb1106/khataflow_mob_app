/// Utility for normalizing phone numbers for comparison.
///
/// All input formats are reduced to their core local digits,
/// stripping country codes (+92 / 92), leading zeros,
/// spaces, dashes, brackets, and plus signs.
///
/// Examples:
///   +923001234567  →  3001234567
///   923001234567   →  3001234567
///   03001234567    →  3001234567
///   0300 123-4567  →  3001234567
class PhoneNormalizer {
  PhoneNormalizer._();

  /// Strips formatting and reduces to a canonical digit-only string.
  ///
  /// Returns an empty string for null / empty / non-numeric inputs.
  static String normalize(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return '';

    // Remove all non-digit characters (spaces, dashes, brackets, +, dots)
    String digits = rawPhone.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return '';

    // Strip leading country code variants:
    //   92XXXXXXXXXX  (11 digits, starts with 92)
    //   0XXXXXXXXXX   (11 digits, starts with 0)
    //   +92XXXXXXXXXX → after stripping '+' → 92XXXXXXXXXX
    if (digits.length == 12 && digits.startsWith('92')) {
      // +923001234567 / 923001234567 → 3001234567
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      // 03001234567 → 3001234567
      digits = digits.substring(1);
    }

    return digits;
  }

  /// Returns true if two phone numbers resolve to the same normalized form.
  /// Both inputs may be raw/un-normalized strings.
  static bool isSameNumber(String? a, String? b) {
    if (a == null || b == null) return false;
    final na = normalize(a);
    final nb = normalize(b);
    return na.isNotEmpty && na == nb;
  }
}
