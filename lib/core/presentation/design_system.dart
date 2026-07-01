import 'package:flutter/material.dart';

class AppDesign {
  // Spacing
  static const double space4 = 3.0;
  static const double space8 = 6.0;
  static const double space12 = 8.0;
  static const double space16 = 12.0;
  static const double space20 = 14.0;
  static const double space24 = 16.0;
  static const double space32 = 20.0;

  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  static const double radiusCard = 24.0;

  static BorderRadius get borderSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderCard => BorderRadius.circular(radiusCard);

  // Shadows
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get premiumShadowDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Premium Palette
  static const Color primaryTeal = Color(0xFF0F766E); // Teal 700
  static const Color primaryEmerald = Color(0xFF10B981); // Emerald 500
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Alert Colors
  static const Color greenReceivable = Color(0xFF10B981);
  static const Color redPayable = Color(0xFFEF4444);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color grayNeutral = Color(0xFF64748B);
}
