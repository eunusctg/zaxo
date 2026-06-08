/// Zaxo dimension constants — paddings, radii, avatar sizes, icon sizes,
/// and button heights. Keeps the UI consistent across the whole app.
class AppDimensions {
  AppDimensions._();

  // ── Padding ────────────────────────────────────────────
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 12.0;
  static const double paddingLg = 16.0;
  static const double paddingXl = 24.0;
  static const double paddingXxl = 32.0;

  // ── Border Radius ──────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 32.0;

  // ── Avatar Sizes ───────────────────────────────────────
  static const double avatarXs = 32.0;
  static const double avatarSm = 40.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;

  // ── Icon Sizes ─────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // ── Button Heights ─────────────────────────────────────
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;

  // ── Chat-specific ──────────────────────────────────────
  static const double chatBubbleMaxWidthFactor = 0.78;
  static const double chatInputMinHeight = 44.0;
  static const double chatInputMaxHeight = 120.0;
  static const double chatInputIconSize = 24.0;

  // ── Status Ring ────────────────────────────────────────
  static const double statusRingWidth = 3.0;
  static const double statusRingGap = 2.0;

  // ── Online Indicator ───────────────────────────────────
  static const double onlineIndicatorSize = 12.0;
  static const double onlineIndicatorBorderWidth = 2.0;

  // ── Unread Badge ───────────────────────────────────────
  static const double unreadBadgeSize = 20.0;
  static const double unreadBadgeMinWidth = 20.0;

  // ── Swipe thresholds ───────────────────────────────────
  static const double swipeReplyThreshold = 60.0;
  static const double swipeArchiveThreshold = 80.0;
}
