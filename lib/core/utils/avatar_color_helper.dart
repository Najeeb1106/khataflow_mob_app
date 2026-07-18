import 'package:flutter/material.dart';

/// Returns a deterministic, stable avatar [Color] for a contact
/// based on their immutable UUID — not their name.
///
/// Using UUID ensures the color does not change when the user renames
/// a contact (spec requirement: "Renaming contact must not change avatar color").
class AvatarColorHelper {
  AvatarColorHelper._();

  static const List<Color> _palette = [
    Color(0xFF0F766E), // Teal 700   (app primary)
    Color(0xFF2563EB), // Blue 600
    Color(0xFF7C3AED), // Violet 600
    Color(0xFFDB2777), // Pink 600
    Color(0xFFD97706), // Amber 600
    Color(0xFF059669), // Emerald 600
    Color(0xFF0284C7), // Sky 600
    Color(0xFFDC2626), // Red 600
  ];

  /// Returns a stable [Color] from the palette, seeded by [uuid].
  ///
  /// The seed is derived from the full UUID string's hash code which is
  /// deterministic for the same input across all platforms in Dart.
  static Color forUuid(String uuid) {
    // Use a simple but stable hash over all UUID characters
    int hash = 0;
    for (final char in uuid.codeUnits) {
      hash = (hash * 31 + char) & 0x7FFFFFFF; // keep positive 31-bit int
    }
    return _palette[hash % _palette.length];
  }
}
