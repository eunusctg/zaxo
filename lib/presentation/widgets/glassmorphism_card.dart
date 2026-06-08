import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';

/// A glassmorphism card widget with:
/// - BackdropFilter with ImageFilter.blur (sigma: 10)
/// - Semi-transparent background
/// - Gradient border
/// - Shadow with colored glow
/// - Hover/press effect
class GlassmorphismCard extends StatefulWidget {
  const GlassmorphismCard({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.opacity = 0.12,
    this.borderRadius = AppDimensions.radiusLg,
    this.borderWidth = 1.0,
    this.borderColor,
    this.tintColor,
    this.glowColor,
    this.glowRadius = 16.0,
    this.glowOpacity = 0.15,
    this.gradientBorderColors,
    this.padding = const EdgeInsets.all(AppDimensions.paddingLg),
    this.margin,
    this.enableHoverEffect = true,
    this.enablePressEffect = true,
    this.onTap,
  });

  final Widget child;

  /// Blur sigma for the backdrop filter.
  final double blurSigma;

  /// Opacity of the semi-transparent background fill.
  final double opacity;

  /// Border radius of the card.
  final double borderRadius;

  /// Width of the gradient border.
  final double borderWidth;

  /// Optional single border color (overrides gradient border).
  final Color? borderColor;

  /// Tint color applied on top of the frosted glass.
  final Color? tintColor;

  /// Color of the outer glow shadow.
  final Color? glowColor;

  /// Spread radius of the outer glow.
  final double glowRadius;

  /// Opacity of the outer glow.
  final double glowOpacity;

  /// Colors for the gradient border. Defaults to primary → tertiary.
  final List<Color>? gradientBorderColors;

  /// Inner padding for the card content.
  final EdgeInsets padding;

  /// Outer margin around the card.
  final EdgeInsets? margin;

  /// Whether to show a subtle hover highlight (on hover-capable devices).
  final bool enableHoverEffect;

  /// Whether to show a press/scale effect on tap.
  final bool enablePressEffect;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  State<GlassmorphismCard> createState() => _GlassmorphismCardState();
}

class _GlassmorphismCardState extends State<GlassmorphismCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = widget.tintColor ??
        (isDark ? Colors.white : Colors.black);
    final glowColor =
        widget.glowColor ?? AppColors.primary;
    final borderGradientColors = widget.gradientBorderColors ??
        [AppColors.primary, AppColors.tertiary];

    return GestureDetector(
      onTapDown: widget.enablePressEffect
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.enablePressEffect
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.enablePressEffect
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: widget.enableHoverEffect
            ? (_) => setState(() => _isHovered = true)
            : null,
        onExit: widget.enableHoverEffect
            ? (_) => setState(() => _isHovered = false)
            : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              // Colored glow shadow
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: widget.glowOpacity),
                  blurRadius: widget.glowRadius,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              // Gradient border
              gradient: widget.borderColor == null
                  ? LinearGradient(
                      colors: borderGradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blurSigma,
                  sigmaY: widget.blurSigma,
                ),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: tint.withValues(
                      alpha: widget.opacity + (_isHovered ? 0.05 : 0),
                    ),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: widget.borderColor != null
                        ? Border.all(
                            color: widget.borderColor!,
                            width: widget.borderWidth,
                          )
                        : GradientBoxBorder(
                            gradient: LinearGradient(
                              colors: borderGradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            width: widget.borderWidth,
                          ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A [BoxBorder] that paints a gradient border.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({
    required this.gradient,
    this.width = 1.0,
  });

  final Gradient gradient;
  final double width;

  @override
  BorderSide get top => BorderSide.none;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    if (borderRadius != null) {
      final rrect = borderRadius.resolve(textDirection).toRRect(rect);
      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  EdgeInsets get dimensions => EdgeInsets.all(width);

  @override
  ShapeBorder scale(double t) => this;

  @override
  GradientBoxBorder add(ShapeBorder? other, {bool reversed = false}) => this;
}
