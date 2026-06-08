import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';

/// Online status indicator with a pulsing animation and outer glow ring.
///
/// Shows a colored dot positioned at the bottom-right of an avatar:
/// - Green → online
/// - Grey → offline
/// - Red → do-not-disturb
///
/// The dot pulses with a scale animation loop, and an outer glow ring
/// expands and fades for the "online" state.
class OnlineStatusIndicator extends StatefulWidget {
  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.isDoNotDisturb = false,
    this.size = AppDimensions.onlineIndicatorSize,
    this.borderWidth = AppDimensions.onlineIndicatorBorderWidth,
    this.borderColor,
  });

  /// Whether the user is currently online.
  final bool isOnline;

  /// If true, shows a red "do not disturb" indicator.
  final bool isDoNotDisturb;

  /// Overall diameter of the dot.
  final double size;

  /// Width of the border ring around the dot.
  final double borderWidth;

  /// Optional override for the border color (defaults to surface color).
  final Color? borderColor;

  @override
  State<OnlineStatusIndicator> createState() => _OnlineStatusIndicatorState();
}

class _OnlineStatusIndicatorState extends State<OnlineStatusIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Pulse: gentle scale oscillation for online dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Glow: expanding and fading outer ring
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Resolve the indicator color based on state.
  Color get _indicatorColor {
    if (widget.isDoNotDisturb) return AppColors.error;
    if (widget.isOnline) return AppColors.onlineIndicator;
    return AppColors.textSecondary; // offline → grey
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.borderColor ?? Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      width: widget.size + widget.borderWidth * 2,
      height: widget.size + widget.borderWidth * 2,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _glowController]),
        builder: (context, child) {
          // Only animate pulse/glow when online
          final pulseScale = widget.isOnline && !widget.isDoNotDisturb
              ? 1.0 + _pulseController.value * 0.15
              : 1.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring (only when online)
              if (widget.isOnline && !widget.isDoNotDisturb)
                _GlowRing(
                  animation: _glowController,
                  color: _indicatorColor,
                  maxSize: widget.size + widget.borderWidth * 2,
                ),

              // Border ring
              Container(
                width: widget.size + widget.borderWidth * 2,
                height: widget.size + widget.borderWidth * 2,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
              ),

              // Inner status dot (with pulse)
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Expanding and fading glow ring painted with [CustomPainter].
class _GlowRing extends StatelessWidget {
  const _GlowRing({
    required this.animation,
    required this.color,
    required this.maxSize,
  });

  final Animation<double> animation;
  final Color color;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(maxSize + 8),
      painter: _GlowRingPainter(
        animation: animation,
        color: color,
        maxSize: maxSize,
      ),
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  _GlowRingPainter({
    required this.animation,
    required this.color,
    required this.maxSize,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double maxSize;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final center = Offset(size.width / 2, size.height / 2);

    // Ring expands from dot size to maxSize + padding
    final minRadius = maxSize / 2;
    final maxRadius = maxSize / 2 + 6;
    final radius = minRadius + (maxRadius - minRadius) * progress;
    final opacity = (1.0 - progress) * 0.4;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.maxSize != maxSize;
  }
}

/// Positioning helper that places the indicator at the bottom-right of an avatar.
class AvatarWithStatus extends StatelessWidget {
  const AvatarWithStatus({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.isOnline,
    this.avatarSize = AppDimensions.avatarMd,
    this.isDoNotDisturb = false,
    this.borderWidth,
    this.borderColor,
  });

  final String? avatarUrl;
  final String name;
  final bool isOnline;
  final double avatarSize;
  final bool isDoNotDisturb;
  final double? borderWidth;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = avatarSize * 0.28;
    final borderW = borderWidth ?? indicatorSize * 0.35;

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar
          Positioned.fill(
            child: CircleAvatar(
              radius: avatarSize / 2,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: avatarSize * 0.4,
                      ),
                    )
                  : null,
            ),
          ),

          // Online indicator (bottom-right)
          Positioned(
            right: -1,
            bottom: -1,
            child: OnlineStatusIndicator(
              isOnline: isOnline,
              isDoNotDisturb: isDoNotDisturb,
              size: indicatorSize,
              borderWidth: borderW,
              borderColor: borderColor,
            ),
          ),
        ],
      ),
    );
  }
}
