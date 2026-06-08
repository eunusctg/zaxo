import 'package:flutter/animation.dart';

/// Zaxo animation constants — durations, curves, and stagger delays.
class AppAnimations {
  AppAnimations._();

  // ── Durations ──────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 1000);

  // ── Curves ─────────────────────────────────────────────
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve overshoot = Cubic(0.68, -0.55, 0.265, 1.55);

  // ── Stagger ────────────────────────────────────────────
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // ── Convenience helpers ────────────────────────────────

  /// Returns a staggered duration for the given [index].
  /// E.g. index 0 → 0ms, index 1 → 50ms, index 2 → 100ms …
  static Duration staggerAt(int index) {
    return Duration(milliseconds: staggerDelay.inMilliseconds * index);
  }

  /// Total stagger duration for [count] items.
  static Duration staggerTotal(int count) {
    return Duration(milliseconds: staggerDelay.inMilliseconds * (count - 1));
  }

  // ── Pulse animation (online indicator, typing, etc.) ───
  static const Duration pulseDuration = Duration(milliseconds: 1500);
  static const Curve pulseCurve = Curves.easeInOut;

  // ── Message send animation ─────────────────────────────
  static const Duration messageSendDuration = Duration(milliseconds: 350);
  static const Curve messageSendCurve = Curves.easeOutCubic;

  // ── Page transition ────────────────────────────────────
  static const Duration pageTransitionDuration = Duration(milliseconds: 350);
  static const Curve pageTransitionCurve = Curves.easeInOutCubicEmphasized;
}
