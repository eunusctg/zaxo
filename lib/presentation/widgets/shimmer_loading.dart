import 'package:flutter/material.dart';

import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';

/// Direction of the shimmer sweep animation.
enum ShimmerDirection {
  ltr,
  rtl,
  ttb,
  btt,
}

/// A performant shimmer loading widget using [ShaderMask].
///
/// Used for message skeletons, image placeholders, and list items.
/// Provides a subtle gradient sweep animation that mimics a loading effect.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.direction = ShimmerDirection.ltr,
  });

  /// The child widget to which the shimmer effect is applied.
  /// Typically a grey placeholder layout.
  final Widget child;

  /// Base color of the shimmer (defaults to surface variant).
  final Color? baseColor;

  /// Highlight color of the shimmer sweep.
  final Color? highlightColor;

  /// Duration of one shimmer cycle.
  final Duration duration;

  /// Direction of the shimmer sweep.
  final ShimmerDirection direction;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Alignment _getBeginAlignment() {
    switch (widget.direction) {
      case ShimmerDirection.ltr:
        return Alignment.centerLeft;
      case ShimmerDirection.rtl:
        return Alignment.centerRight;
      case ShimmerDirection.ttb:
        return Alignment.topCenter;
      case ShimmerDirection.btt:
        return Alignment.bottomCenter;
    }
  }

  Alignment _getEndAlignment() {
    switch (widget.direction) {
      case ShimmerDirection.ltr:
        return Alignment.centerRight;
      case ShimmerDirection.rtl:
        return Alignment.centerLeft;
      case ShimmerDirection.ttb:
        return Alignment.bottomCenter;
      case ShimmerDirection.btt:
        return Alignment.topCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant);
    final highlight = widget.highlightColor ??
        (isDark
            ? AppColors.outline.withValues(alpha: 0.3)
            : AppColors.lightOutline.withValues(alpha: 0.3));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final slidePercent = _controller.value;
            return LinearGradient(
              begin: _getBeginAlignment(),
              end: _getEndAlignment(),
              colors: [
                base,
                highlight,
                base,
              ],
              stops: [
                (slidePercent - 0.3).clamp(0.0, 1.0),
                slidePercent,
                (slidePercent + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A ready-made message skeleton placeholder for chat lists.
class MessageShimmer extends StatelessWidget {
  const MessageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      child: _SkeletonRow(),
    );
  }
}

/// A ready-made list item skeleton.
class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: List.generate(
          itemCount,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg,
              vertical: AppDimensions.paddingSm,
            ),
            child: _SkeletonRow(),
          ),
        ),
      ),
    );
  }
}

/// A ready-made image placeholder skeleton.
class ImageShimmer extends StatelessWidget {
  const ImageShimmer({super.key, this.width = double.infinity, this.height = 200});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar placeholder
        Container(
          width: AppDimensions.avatarMd,
          height: AppDimensions.avatarMd,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.avatarMd / 2),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMd),
        // Text lines
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title line
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle line
              Container(
                height: 12,
                width: MediaQuery.sizeOf(context).width * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
