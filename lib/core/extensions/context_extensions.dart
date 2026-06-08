import 'package:flutter/material.dart';

/// Convenience extensions on [BuildContext] for common operations.
extension ContextExtensions on BuildContext {
  // ── MediaQuery shortcuts ───────────────────────────────

  /// Width of the current screen.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Height of the current screen.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Current [EdgeInsets] for padding (safe area, keyboard, etc.).
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Current keyboard height (0 if keyboard is hidden).
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  /// Whether the keyboard is currently visible.
  bool get isKeyboardVisible => keyboardHeight > 0;

  // ── Theme shortcuts ────────────────────────────────────

  /// The current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// The current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Whether the current theme is dark.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── SnackBar ───────────────────────────────────────────

  /// Shows a [SnackBar] with the given [message].
  void showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(this)?.hideCurrentSnackBar();
    ScaffoldMessenger.maybeOf(this)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(
          milliseconds: isError ? 4000 : 2500,
        ),
      ),
    );
  }
}
