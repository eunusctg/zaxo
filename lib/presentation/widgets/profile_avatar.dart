import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/presentation/widgets/status_ring.dart';

/// Size variants for the profile avatar.
enum AvatarSize {
  xs(AppDimensions.avatarXs),
  sm(AppDimensions.avatarSm),
  md(AppDimensions.avatarMd),
  lg(AppDimensions.avatarLg),
  xl(AppDimensions.avatarXl);

  final double value;
  const AvatarSize(this.value);
}

/// A circular profile avatar with online indicator, initials fallback,
/// status ring overlay, and tap animation.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.md,
    this.isOnline = false,
    this.showOnlineIndicator = false,
    this.showStatusRing = false,
    this.isStatusViewed = false,
    this.statusSegmentCount = 0,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  });

  /// Remote image URL for the avatar.
  final String? imageUrl;

  /// Display name used to generate initials when no image is available.
  final String? name;

  /// Size variant.
  final AvatarSize size;

  /// Whether the user is currently online.
  final bool isOnline;

  /// Whether to show the green online dot.
  final bool showOnlineIndicator;

  /// Whether to wrap the avatar with a status ring.
  final bool showStatusRing;

  /// If showing a status ring, whether the status has been viewed.
  final bool isStatusViewed;

  /// Number of status segments to render in the ring.
  final int statusSegmentCount;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional border color override.
  final Color? borderColor;

  /// Optional background color override for the initials fallback.
  final Color? backgroundColor;

  // ── Helpers ──────────────────────────────────────────────

  /// Extracts up to two initials from [name].
  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Gradient used when rendering initials.
  LinearGradient get _initialsGradient => LinearGradient(
        colors: [
          AppColors.primary,
          AppColors.tertiary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Widget build(BuildContext context) {
    final double avatarSize = size.value;
    final double ringPadding =
        showStatusRing ? AppDimensions.statusRingWidth * 2 + AppDimensions.statusRingGap : 0.0;
    final double totalSize = avatarSize + ringPadding * 2;

    Widget avatar = _buildAvatarContent(avatarSize);

    // Wrap with status ring if requested.
    if (showStatusRing) {
      avatar = StatusRing(
        segmentCount: statusSegmentCount,
        isViewed: isStatusViewed,
        size: totalSize,
        ringWidth: AppDimensions.statusRingWidth,
        gap: AppDimensions.statusRingGap,
        child: Padding(
          padding: EdgeInsets.all(ringPadding),
          child: avatar,
        ),
      );
    }

    // Online indicator.
    if (showOnlineIndicator) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: _OnlineDot(isOnline: isOnline, avatarSize: avatarSize),
          ),
        ],
      );
    }

    // Tap animation wrapper.
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar
            .animate(onPlay: (c) => c.forward())
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(0.95, 0.95),
              duration: 100.ms,
            )
            .then()
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.0, 1.0),
              duration: 100.ms,
            ),
      );
    }

    return SizedBox(
      width: showStatusRing ? totalSize : avatarSize,
      height: showStatusRing ? totalSize : avatarSize,
      child: avatar,
    );
  }

  Widget _buildAvatarContent(double size) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsFallback(size),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitialsFallback(size);
          },
        ),
      );
    }

    return _buildInitialsFallback(size);
  }

  Widget _buildInitialsFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: backgroundColor != null ? null : _initialsGradient,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 2),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }
}

/// Small online indicator dot positioned at the bottom-right of the avatar.
class _OnlineDot extends StatelessWidget {
  const _OnlineDot({
    required this.isOnline,
    required this.avatarSize,
  });

  final bool isOnline;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final dotSize = AppDimensions.onlineIndicatorSize;
    final borderWidth = AppDimensions.onlineIndicatorBorderWidth;

    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.onlineIndicator : AppColors.outline,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: borderWidth,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}
