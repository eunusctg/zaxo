import 'package:flutter/material.dart';

/// Zaxo typography system.
/// Uses **Outfit** for headings and **Inter** for body text.
class AppTypography {
  AppTypography._();

  // ── Font families ──────────────────────────────────────
  static const String headingFont = 'Outfit';
  static const String bodyFont = 'Inter';

  // ── Pre-defined TextStyles ─────────────────────────────

  /// Display Large — Outfit Bold 57
  static const TextStyle displayLarge = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w700,
    fontSize: 57,
    height: 1.12,
    letterSpacing: -0.25,
  );

  /// Display Medium — Outfit Bold 45
  static const TextStyle displayMedium = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w700,
    fontSize: 45,
    height: 1.16,
    letterSpacing: 0,
  );

  /// Display Small — Outfit Bold 36
  static const TextStyle displaySmall = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w700,
    fontSize: 36,
    height: 1.22,
    letterSpacing: 0,
  );

  /// Headline Large — Outfit SemiBold 32
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 1.25,
    letterSpacing: 0,
  );

  /// Headline Medium — Outfit SemiBold 28
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 1.29,
    letterSpacing: 0,
  );

  /// Headline Small — Outfit SemiBold 24
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.33,
    letterSpacing: 0,
  );

  /// Title Large — Outfit Medium 22
  static const TextStyle titleLarge = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w500,
    fontSize: 22,
    height: 1.27,
    letterSpacing: 0,
  );

  /// Title Medium — Outfit Medium 16
  static const TextStyle titleMedium = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.50,
    letterSpacing: 0.15,
  );

  /// Title Small — Outfit Medium 14
  static const TextStyle titleSmall = TextStyle(
    fontFamily: headingFont,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// Body Large — Inter Regular 16
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.50,
    letterSpacing: 0.50,
  );

  /// Body Medium — Inter Regular 14
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// Body Small — Inter Regular 12
  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.33,
    letterSpacing: 0.40,
  );

  /// Label Large — Inter Medium 14
  static const TextStyle labelLarge = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.10,
  );

  /// Label Medium — Inter Medium 12
  static const TextStyle labelMedium = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.33,
    letterSpacing: 0.50,
  );

  /// Label Small — Inter Medium 12
  static const TextStyle labelSmall = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.33,
    letterSpacing: 0.50,
  );

  // ── TextTheme factory ──────────────────────────────────

  /// Returns a complete [TextTheme] using the Zaxo typography system.
  static TextTheme textTheme({Color? color}) {
    final c = color;
    return TextTheme(
      displayLarge: c != null ? displayLarge.copyWith(color: c) : displayLarge,
      displayMedium: c != null ? displayMedium.copyWith(color: c) : displayMedium,
      displaySmall: c != null ? displaySmall.copyWith(color: c) : displaySmall,
      headlineLarge: c != null ? headlineLarge.copyWith(color: c) : headlineLarge,
      headlineMedium: c != null ? headlineMedium.copyWith(color: c) : headlineMedium,
      headlineSmall: c != null ? headlineSmall.copyWith(color: c) : headlineSmall,
      titleLarge: c != null ? titleLarge.copyWith(color: c) : titleLarge,
      titleMedium: c != null ? titleMedium.copyWith(color: c) : titleMedium,
      titleSmall: c != null ? titleSmall.copyWith(color: c) : titleSmall,
      bodyLarge: c != null ? bodyLarge.copyWith(color: c) : bodyLarge,
      bodyMedium: c != null ? bodyMedium.copyWith(color: c) : bodyMedium,
      bodySmall: c != null ? bodySmall.copyWith(color: c) : bodySmall,
      labelLarge: c != null ? labelLarge.copyWith(color: c) : labelLarge,
      labelMedium: c != null ? labelMedium.copyWith(color: c) : labelMedium,
      labelSmall: c != null ? labelSmall.copyWith(color: c) : labelSmall,
    );
  }
}
