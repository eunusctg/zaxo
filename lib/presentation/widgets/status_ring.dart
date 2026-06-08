import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';

/// A circular status ring drawn around a child widget using [CustomPainter].
///
/// Features:
/// - Multiple arc segments (one per status)
/// - Gradient purple→mint for unseen, grey for seen
/// - Progress animation when viewing
/// - Scale animation on new status
class StatusRing extends StatelessWidget {
  const StatusRing({
    super.key,
    required this.child,
    this.segmentCount = 1,
    this.isViewed = false,
    this.viewingProgress = 0.0,
    this.isViewing = false,
    this.viewingIndex = 0,
    this.size = AppDimensions.avatarMd + AppDimensions.statusRingWidth * 2,
    this.ringWidth = AppDimensions.statusRingWidth,
    this.gap = AppDimensions.statusRingGap,
    this.onTap,
  });

  /// The widget inside the ring (typically an avatar).
  final Widget child;

  /// Number of status segments to draw.
  final int segmentCount;

  /// Whether the statuses have been viewed (grey ring).
  final bool isViewed;

  /// Progress (0.0–1.0) of the currently-viewing segment.
  final double viewingProgress;

  /// Whether the ring is in "viewing" mode (one segment fills progressively).
  final bool isViewing;

  /// Index of the segment currently being viewed.
  final int viewingIndex;

  /// Total outer size of the ring area.
  final double size;

  /// Stroke width of the ring arcs.
  final double ringWidth;

  /// Angular gap between segments (in logical pixels mapped to sweep angle).
  final double gap;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget ring = CustomPaint(
      size: Size(size, size),
      painter: _StatusRingPainter(
        segmentCount: segmentCount,
        isViewed: isViewed,
        viewingProgress: viewingProgress,
        isViewing: isViewing,
        viewingIndex: viewingIndex,
        ringWidth: ringWidth,
        gapAngle: _gapToAngle(),
      ),
      child: child,
    );

    // Scale-in animation for new status.
    if (!isViewed && segmentCount > 0) {
      ring = ring
          .animate(onPlay: (c) => c.forward())
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 200.ms);
    }

    if (onTap != null) {
      ring = GestureDetector(onTap: onTap, child: ring);
    }

    return ring;
  }

  /// Converts the gap size to a sweep angle in radians.
  double _gapToAngle() {
    // Each gap is roughly `gap` pixels on the circumference.
    final circumference = 2 * math.pi * (size / 2);
    if (circumference <= 0) return 0.05;
    return (gap / circumference) * 2 * math.pi;
  }
}

/// CustomPainter that draws gradient arc segments around a circle.
class _StatusRingPainter extends CustomPainter {
  _StatusRingPainter({
    required this.segmentCount,
    required this.isViewed,
    required this.viewingProgress,
    required this.isViewing,
    required this.viewingIndex,
    required this.ringWidth,
    required this.gapAngle,
  });

  final int segmentCount;
  final bool isViewed;
  final double viewingProgress;
  final bool isViewing;
  final int viewingIndex;
  final double ringWidth;
  final double gapAngle;

  @override
  void paint(Canvas canvas, Size size) {
    if (segmentCount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - ringWidth) / 2;
    if (radius <= 0) return;

    final totalGapAngle = gapAngle * segmentCount;
    final availableSweep = (2 * math.pi) - totalGapAngle;
    final segmentSweep = availableSweep / segmentCount;
    final startAngle = -math.pi / 2; // Top of circle

    for (int i = 0; i < segmentCount; i++) {
      final sweepStart = startAngle + i * (segmentSweep + gapAngle);

      // Determine the sweep for this segment.
      double sweep;
      if (isViewing && i == viewingIndex) {
        sweep = segmentSweep * viewingProgress.clamp(0.0, 1.0);
      } else if (isViewing && i < viewingIndex) {
        sweep = segmentSweep; // Fully completed
      } else if (isViewing && i > viewingIndex) {
        sweep = 0; // Not yet viewed
      } else {
        sweep = segmentSweep;
      }

      if (sweep <= 0) continue;

      // Colors: gradient for unseen, grey for seen.
      final List<Color> colors;
      if (isViewed && !(isViewing && i == viewingIndex)) {
        colors = [
          AppColors.outline,
          AppColors.outline.withValues(alpha: 0.6),
        ];
      } else {
        colors = [
          AppColors.primary,
          AppColors.secondary,
        ];
      }

      final shader = SweepGradient(
        startAngle: sweepStart,
        endAngle: sweepStart + sweep,
        colors: colors,
        stops: const [0.0, 1.0],
        transform: GradientRotation(sweepStart),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      final paint = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sweepStart,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StatusRingPainter oldDelegate) {
    return oldDelegate.segmentCount != segmentCount ||
        oldDelegate.isViewed != isViewed ||
        oldDelegate.viewingProgress != viewingProgress ||
        oldDelegate.isViewing != isViewing ||
        oldDelegate.viewingIndex != viewingIndex;
  }
}
