import 'package:flutter/material.dart';

/// Zaxo color palette — Deep Purple / Mint Green / Hot Pink on dark navy.
/// All colors are defined as static constants for easy access throughout the app.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color secondary = Color(0xFF06D6A0);
  static const Color secondaryLight = Color(0xFF34D399);

  static const Color tertiary = Color(0xFFF72585);

  // ── Surfaces ───────────────────────────────────────────
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF252540);
  static const Color outline = Color(0xFF3A3A5C);

  // ── Text ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C3);

  // ── Status ─────────────────────────────────────────────
  static const Color onlineIndicator = Color(0xFF06D6A0);
  static const Color unreadBadge = Color(0xFFF72585);

  // ── Semantic ───────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF06D6A0);
  static const Color warning = Color(0xFFF59E0B);

  // ── Gradients ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient chatBubbleSent = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chatBubbleReceived = LinearGradient(
    colors: [surfaceVariant, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light theme overrides ──────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F5);
  static const Color lightOutline = Color(0xFFD1D5DB);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
}
