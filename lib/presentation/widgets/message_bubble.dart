import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/core/constants/app_animations.dart';
import 'package:zaxo/core/utils/date_formatter.dart';
import 'package:zaxo/domain/entities/message.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Reusable message bubble widget with:
/// - Custom clip path for bubble tail
/// - Gradient background for sent messages
/// - Scale animation on appear
/// - Tap feedback with haptic
/// - Support for all message types (text, image, voice, video, document,
///   location, contact)
/// - Status icons (check / check-check with colors)
/// - Star indicator
/// - Reply preview
class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onReplySwipe,
    this.showTail = true,
    this.replyToContent,
    this.replyToSenderName,
    this.currentUserId = '',
  });

  /// The message entity to render.
  final Message message;

  /// Whether this message was sent by the current user.
  final bool isMine;

  /// Called on single tap (e.g. show timestamp).
  final VoidCallback? onTap;

  /// Called on double tap (e.g. heart reaction).
  final VoidCallback? onDoubleTap;

  /// Called on long press (e.g. context menu).
  final VoidCallback? onLongPress;

  /// Called when user swipes right to reply.
  final VoidCallback? onReplySwipe;

  /// Whether to show the bubble tail (only for the last message in a group).
  final bool showTail;

  /// Content of the message being replied to.
  final String? replyToContent;

  /// Sender name of the message being replied to.
  final String? replyToSenderName;

  /// Current user ID for determining sent vs received.
  final String currentUserId;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  bool _showTimestamp = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppAnimations.messageSendDuration,
    )..forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _showTimestamp = !_showTimestamp);
    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    widget.onDoubleTap?.call();
  }

  void _handleLongPress() {
    HapticFeedback.heavyImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
          parent: _scaleController,
          curve: AppAnimations.messageSendCurve,
        ),
      ),
      child: Align(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.sizeOf(context).width *
                AppDimensions.chatBubbleMaxWidthFactor,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.isMine ? 48.0 : 8.0,
              right: widget.isMine ? 8.0 : 48.0,
              top: 2.0,
              bottom: 2.0,
            ),
            child: GestureDetector(
              onTap: _handleTap,
              onDoubleTap: _handleDoubleTap,
              onLongPress: _handleLongPress,
              child: ClipPath(
                clipper: _BubbleTailClipper(
                  isMine: widget.isMine,
                  showTail: widget.showTail,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: widget.isMine
                        ? AppColors.chatBubbleSent
                        : AppColors.chatBubbleReceived,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: widget.isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reply preview
                      if (widget.replyToContent != null) _buildReplyPreview(),

                      // Message content based on type
                      _buildMessageContent(),

                      // Star indicator
                      if (widget.message.isStarred) _buildStarIndicator(),

                      // Timestamp + status row
                      _buildTimestampRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build reply preview shown above the message content.
  Widget _buildReplyPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (widget.isMine ? Colors.white : AppColors.primary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: widget.isMine
                ? Colors.white.withValues(alpha: 0.5)
                : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.replyToSenderName ?? 'Unknown',
            style: TextStyle(
              color: widget.isMine
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.replyToContent ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the message content based on the message type.
  Widget _buildMessageContent() {
    if (widget.message.isDeleted) {
      return _buildDeletedMessage();
    }

    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.image:
        return _buildImageContent();
      case MessageType.voice:
        return _buildVoiceContent();
      case MessageType.video:
        return _buildVideoContent();
      case MessageType.document:
        return _buildDocumentContent();
      case MessageType.location:
        return _buildLocationContent();
      case MessageType.contact:
        return _buildContactContent();
    }
  }

  Widget _buildTextContent() {
    final textColor = widget.isMine ? Colors.white : AppColors.textPrimary;

    return SelectableText(
      widget.message.content,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildImageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 240,
              maxHeight: 300,
            ),
            child: widget.message.mediaUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.message.mediaUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  )
                : Container(
                    height: 200,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image, size: 48),
                  ),
          ),
        ),
        if (widget.message.content.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildTextContent(),
        ],
      ],
    );
  }

  Widget _buildVoiceContent() {
    final textColor = widget.isMine ? Colors.white : AppColors.textPrimary;
    final iconColor = widget.isMine ? Colors.white70 : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_fill, color: iconColor, size: 28),
        const SizedBox(width: 8),
        // Simple waveform placeholder
        Expanded(
          child: CustomPaint(
            size: const Size.fromHeight(24),
            painter: _WaveformPainter(
              color: iconColor,
              barCount: 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '0:${widget.message.content.padLeft(2, '0')}',
          style: TextStyle(color: textColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVideoContent() {
    final iconColor = widget.isMine ? Colors.white70 : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 240,
                  maxHeight: 200,
                ),
                child: widget.message.mediaUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.message.mediaUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: AppColors.surfaceVariant,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.videocam, size: 48),
                        ),
                      )
                    : Container(
                        height: 180,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.videocam, size: 48),
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow, color: iconColor, size: 28),
            ),
          ],
        ),
        if (widget.message.content.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildTextContent(),
        ],
      ],
    );
  }

  Widget _buildDocumentContent() {
    final textColor = widget.isMine ? Colors.white : AppColors.textPrimary;
    final iconColor = widget.isMine ? Colors.white70 : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file, color: iconColor, size: 36),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.message.mediaType?.toUpperCase() ?? 'DOCUMENT',
                style: TextStyle(
                  color: iconColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 220,
            height: 140,
            color: AppColors.surfaceVariant,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.map, size: 48, color: AppColors.primary),
                Positioned(
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.tertiary,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.message.content.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.message.content,
            style: TextStyle(
              color: widget.isMine ? Colors.white : AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactContent() {
    final textColor = widget.isMine ? Colors.white : AppColors.textPrimary;
    final iconColor = widget.isMine ? Colors.white70 : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Icon(Icons.person, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message.content,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.message.mediaUrl ?? 'Contact',
                style: TextStyle(color: iconColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeletedMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.block,
          size: 16,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          'This message was deleted',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStarIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 14,
            color: AppColors.warning.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow() {
    final timeColor = widget.isMine ? Colors.white60 : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showTimestamp)
            Text(
              DateFormatter.formatMessageTime12(widget.message.createdAt),
              style: TextStyle(color: timeColor, fontSize: 11),
            )
          else
            Text(
              DateFormatter.formatMessageTime(widget.message.createdAt),
              style: TextStyle(color: timeColor, fontSize: 11),
            ),
          if (widget.isMine) ...[
            const SizedBox(width: 4),
            _buildStatusIcon(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    final color = _statusColor;
    final icon = _statusIcon;

    return Icon(icon, size: 16, color: color);
  }

  Color get _statusColor {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Colors.white38;
      case MessageStatus.sent:
        return Colors.white60;
      case MessageStatus.delivered:
        return Colors.white70;
      case MessageStatus.read:
        return AppColors.secondary;
      case MessageStatus.failed:
        return AppColors.error;
    }
  }

  IconData get _statusIcon {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }
}

// ══════════════════════════════════════════════════════════
//  Bubble Tail Clipper
// ══════════════════════════════════════════════════════════

/// Custom clip path that creates a chat bubble tail on the appropriate side.
class _BubbleTailClipper extends CustomClipper<Path> {
  _BubbleTailClipper({
    required this.isMine,
    required this.showTail,
  });

  final bool isMine;
  final bool showTail;

  @override
  Path getClip(Size size) {
    if (!showTail) {
      return Path()..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));
    }

    const tailWidth = 8.0;
    const tailHeight = 12.0;
    const radius = 16.0;

    final path = Path();

    if (isMine) {
      // Right tail for sent messages
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(
          size.width, size.height, size.width - radius, size.height);
      // Tail on the right-bottom
      path.lineTo(tailWidth + 4, size.height);
      path.lineTo(0, size.height - tailHeight);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
    } else {
      // Left tail for received messages
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(
          size.width, size.height, size.width - radius, size.height);
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      // Tail on the left-bottom
      path.lineTo(0, size.height - tailHeight);
      path.lineTo(tailWidth + 4, size.height);
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BubbleTailClipper oldClipper) {
    return isMine != oldClipper.isMine || showTail != oldClipper.showTail;
  }
}

// ══════════════════════════════════════════════════════════
//  Waveform Painter
// ══════════════════════════════════════════════════════════

/// Simple waveform visualization for voice messages.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.color,
    this.barCount = 28,
  });

  final Color color;
  final int barCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    final barSpacing = size.width / barCount;
    final center = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      // Pseudo-random bar height based on index
      final factor = (i * 7 + 3) % 5 / 5;
      final barHeight = size.height * 0.2 + size.height * 0.6 * factor;
      final x = i * barSpacing + barSpacing / 2;

      canvas.drawLine(
        Offset(x, center - barHeight / 2),
        Offset(x, center + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.barCount != barCount;
  }
}
