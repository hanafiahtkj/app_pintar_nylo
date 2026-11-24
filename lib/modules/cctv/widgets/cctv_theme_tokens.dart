import 'package:flutter/material.dart';

/// Soft, modern visual tokens for the native CCTV module, aligned with
/// `app_pintar_nylo`'s light/dark palette and typography scale.
class CctvTokens {
  final bool isDark;

  const CctvTokens._(this.isDark);

  factory CctvTokens.of(BuildContext context) {
    return CctvTokens._(Theme.of(context).brightness == Brightness.dark);
  }

  // Brand & interactive colors aligned with app_pintar_nylo
  Color get primary =>
      isDark ? const Color(0xFF7CB2FF) : const Color(0xFF1D5BD6);
  Color get primaryOnFill => isDark ? const Color(0xFF0E1A38) : Colors.white;
  Color get primarySoft =>
      isDark ? const Color(0x247CB2FF) : const Color(0x141D5BD6);

  // Soft layered surfaces (neither harsh nor overly flat)
  Color get pageBg =>
      isDark ? const Color(0xFF15111E) : const Color(0xFFF3F6FA);
  Color get surface => isDark ? const Color(0xFF1E1929) : Colors.white;
  Color get surfaceElevated =>
      isDark ? const Color(0xFF251F33) : Colors.white;
  Color get surfaceSubtle =>
      isDark ? const Color(0xFF2C253B) : const Color(0xFFF1F5F9);

  // Soft hairline borders & dividers
  Color get border =>
      isDark ? const Color(0xFF342C46) : const Color(0xFFE8EEF5);
  Color get divider =>
      isDark ? const Color(0xFF2D263D) : const Color(0xFFF0F4F8);

  // Text hierarchy
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A1D2B);
  Color get textSecondary =>
      isDark ? const Color(0xFFC2BCD4) : const Color(0xFF4B5565);
  Color get textMuted =>
      isDark ? const Color(0xFF9088A6) : const Color(0xFF6B778C);

  // Semantic status colors (softened tints)
  Color get online => const Color(0xFF10B981);
  Color get onlineText =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  Color get onlineSoft =>
      isDark ? const Color(0x1F10B981) : const Color(0xFFECFDF5);

  Color get offline => const Color(0xFFF43F5E);
  Color get offlineText =>
      isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
  Color get offlineSoft =>
      isDark ? const Color(0x1FF43F5E) : const Color(0xFFFFF1F2);

  Color get warningText =>
      isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
  Color get warningSoft =>
      isDark ? const Color(0x1FF59E0B) : const Color(0xFFFFFBEB);

  // Soft ambient shadows so surfaces feel gently lifted without harsh edges
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];

  List<BoxShadow> get sectionShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];

  List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  // Consistent 5-step typography scale (11, 12, 13, 15, 17)
  TextStyle get caption => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textMuted,
        height: 1.3,
      );

  TextStyle get label => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        height: 1.3,
      );

  TextStyle get body => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.4,
      );

  TextStyle get title => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.28,
      );

  TextStyle get heading => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.2,
      );

  // Shared soft geometry
  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusPill = 20;
  static const double minTouchTarget = 44;
  static const double compactMobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
  static const double maxContentWidth = 1360;
}
