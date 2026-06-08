import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

/// Central theme configuration for Zaxo.
/// Provides light and dark [ThemeData] plus glassmorphism / neumorphism helpers.
class AppTheme {
  AppTheme._();

  // ── Dark Theme (default) ───────────────────────────────

  static ThemeData darkTheme() {
    final colorScheme = const ColorScheme.dark().copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      onSecondary: AppColors.background,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.15),
      onSecondaryContainer: AppColors.secondaryLight,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiary.withValues(alpha: 0.15),
      onTertiaryContainer: AppColors.tertiary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.15),
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.outline,
      outlineVariant: AppColors.outline.withValues(alpha: 0.5),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.lightSurface,
      onInverseSurface: AppColors.lightTextPrimary,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ── Light Theme ────────────────────────────────────────

  static ThemeData lightTheme() {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.15),
      onSecondaryContainer: AppColors.secondary,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiary.withValues(alpha: 0.12),
      onTertiaryContainer: AppColors.tertiary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.12),
      onErrorContainer: AppColors.error,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutline.withValues(alpha: 0.5),
      shadow: Colors.black12,
      scrim: Colors.black54,
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.textPrimary,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ── Shared builder ─────────────────────────────────────

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme(
        color: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: colorScheme.surface,

      // ── AppBar ────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: isDark ? 1 : 0.5,
        centerTitle: false,
        backgroundColor: isDark
            ? AppColors.surface
            : AppColors.lightSurface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: AppDimensions.iconLg,
        ),
      ),

      // ── Card ──────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        color: colorScheme.surfaceContainerHighest,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingXs,
        ),
      ),

      // ── ElevatedButton ────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingXl,
            vertical: AppDimensions.paddingMd,
          ),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          side: BorderSide(color: colorScheme.outline),
          foregroundColor: colorScheme.primary,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingXl,
            vertical: AppDimensions.paddingMd,
          ),
        ),
      ),

      // ── TextButton ────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeightSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          foregroundColor: colorScheme.primary,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLg,
            vertical: AppDimensions.paddingSm,
          ),
        ),
      ),

      // ── InputDecoration ───────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceVariant
            : AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLg,
          vertical: AppDimensions.paddingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: AppTypography.labelSmall.copyWith(
          color: colorScheme.primary,
        ),
      ),

      // ── BottomNavigationBar ───────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark
            ? AppColors.surface
            : AppColors.lightSurface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        elevation: 8,
      ),

      // ── NavigationBar (M3) ───────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.surface
            : AppColors.lightSurface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.primary,
              size: AppDimensions.iconLg,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: AppDimensions.iconLg,
          );
        }),
      ),

      // ── FloatingActionButton ─────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        extendedTextStyle: AppTypography.labelLarge,
      ),

      // ── Chip ─────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        deleteIconColor: colorScheme.onSurfaceVariant,
        labelStyle: AppTypography.labelLarge.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: AppTypography.labelLarge.copyWith(
          color: colorScheme.primary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSm,
          vertical: AppDimensions.paddingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        side: BorderSide(color: colorScheme.outline),
      ),

      // ── Dialog ───────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: isDark
            ? AppColors.surface
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── BottomSheet ──────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? AppColors.surface
            : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
      ),

      // ── Divider ──────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.3),
        thickness: 0.5,
        space: 0,
      ),

      // ── Icon ─────────────────────────────────────────
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppDimensions.iconLg,
      ),

      // ── SnackBar ─────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        backgroundColor: isDark
            ? AppColors.surfaceVariant
            : AppColors.lightSurfaceVariant,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        ),
        actionTextColor: colorScheme.primary,
      ),

      // ── Switch ───────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.outline.withValues(alpha: 0.3);
        }),
      ),

      // ── ProgressIndicator ────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // ── TabBar ───────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: colorScheme.primary,
      ),

      // ── PopupMenu ────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.surfaceVariant : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // ── Tooltip ──────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        ),
        waitDuration: const Duration(seconds: 1),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Glassmorphism decoration helper
  // ══════════════════════════════════════════════════════

  /// Returns a [BoxDecoration] with a frosted-glass effect.
  ///
  /// ```dart
  /// Container(
  ///   decoration: AppTheme.glassDecoration(context),
  ///   child: ...
  /// )
  /// ```
  static BoxDecoration glassDecoration(
    BuildContext context, {
    Color? tintColor,
    double blurSigma = 20,
    double opacity = 0.15,
    double radius = AppDimensions.radiusLg,
    double borderWidth = 1,
    Color? borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = tintColor ?? (isDark ? Colors.white : Colors.black);

    // Note: For glassmorphism, use BackdropFilter widget wrapping
    // This returns a basic decoration for use in non-BackdropFilter contexts
    return BoxDecoration(
      color: tint.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.3)),
        width: borderWidth,
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Neumorphism decoration helper
  // ══════════════════════════════════════════════════════

  /// Returns a [BoxDecoration] with a neumorphic (soft-UI) effect.
  ///
  /// Works best on dark surfaces.
  static BoxDecoration neumorphismDecoration({
    Color? baseColor,
    double radius = AppDimensions.radiusMd,
    double distance = 6,
    double blur = 12,
    Color? lightShadowColor,
    Color? darkShadowColor,
  }) {
    final base = baseColor ?? AppColors.surface;
    final light = lightShadowColor ?? Colors.white.withValues(alpha: 0.05);
    final dark = darkShadowColor ?? Colors.black.withValues(alpha: 0.5);

    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: light,
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: dark,
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
      ],
    );
  }

  /// A convex (raised) variant of the neumorphic decoration.
  static BoxDecoration neumorphismConvex({
    Color? baseColor,
    double radius = AppDimensions.radiusMd,
    double distance = 4,
    double blur = 8,
  }) {
    return neumorphismDecoration(
      baseColor: baseColor,
      radius: radius,
      distance: distance,
      blur: blur,
    );
  }

  /// An inset (pressed) variant of the neumorphic decoration.
  static BoxDecoration neumorphismInset({
    Color? baseColor,
    double radius = AppDimensions.radiusMd,
    double distance = 4,
    double blur = 8,
  }) {
    final base = baseColor ?? AppColors.surface;

    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.03),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
      ],
    );
  }
}
