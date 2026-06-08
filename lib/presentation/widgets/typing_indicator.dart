import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_animations.dart';

/// Typing indicator widget with three circles that bounce in a staggered
/// spring-like animation.
///
/// Each dot uses a physics-based spring with a staggered delay.
/// The dots are rendered in the primary color with varying opacity.
/// Smooth enter/exit animation is provided via fade + scale.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.dotSize = 8.0,
    this.dotSpacing = 4.0,
    this.color,
    this.visible = true,
  });

  /// Diameter of each dot.
  final double dotSize;

  /// Horizontal spacing between dots.
  final double dotSpacing;

  /// Base color for the dots. Defaults to primary color.
  final Color? color;

  /// Whether the indicator is visible. Toggling this triggers a
  /// smooth enter/exit animation.
  final bool visible;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _visibilityController;

  @override
  void initState() {
    super.initState();

    // Bounce loop for the three dots
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Visibility fade/scale
    _visibilityController = AnimationController(
      vsync: this,
      duration: AppAnimations.durationNormal,
    );

    if (widget.visible) {
      _visibilityController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  /// Calculate the Y offset for a dot based on its index (0, 1, 2).
  double _dotOffset(int index) {
    // Each dot has a stagger delay of ~150ms
    const staggerFraction = 0.107; // ~150ms of 1400ms
    final shiftedValue =
        (_bounceController.value - index * staggerFraction) % 1.0;

    // Bounce curve: rise quickly, fall with overshoot-like feel
    if (shiftedValue < 0.3) {
      // Rising phase
      final t = shiftedValue / 0.3;
      return -math.sin(t * math.pi / 2) * (widget.dotSize * 0.8);
    } else if (shiftedValue < 0.5) {
      // Falling phase
      final t = (shiftedValue - 0.3) / 0.2;
      return -math.cos(t * math.pi / 2) * (widget.dotSize * 0.8);
    }
    // Rest phase
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return FadeTransition(
      opacity: _visibilityController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(
            parent: _visibilityController,
            curve: Curves.easeOutBack,
          ),
        ),
        child: AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(3, (index) {
                final offset = _dotOffset(index);
                final opacity = 0.4 + (index * 0.2);

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : widget.dotSpacing,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, offset),
                    child: Container(
                      width: widget.dotSize,
                      height: widget.dotSize,
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: opacity + 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

/// A slightly larger, padded version of [TypingIndicator] meant to be
/// embedded inside a chat message bubble to simulate the other user typing.
class TypingBubble extends StatelessWidget {
  const TypingBubble({
    super.key,
    this.color,
    this.visible = true,
  });

  final Color? color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariant
              : AppColors.lightSurfaceVariant,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: TypingIndicator(
          color: color,
          visible: visible,
        ),
      ),
    );
  }
}
