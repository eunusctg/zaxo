import 'package:equatable/equatable.dart';

abstract class StatusEvent extends Equatable {
  const StatusEvent();

  @override
  List<Object?> get props => [];
}

/// Load all visible statuses from contacts.
class StatusLoadRequested extends StatusEvent {
  const StatusLoadRequested();
}

/// Create a new status update.
class StatusCreated extends StatusEvent {
  final StatusType type;
  final String content;

  /// URL for media (image/video). Null for text statuses.
  final String? mediaUrl;

  /// Background color hex code for text statuses.
  final String? bgColor;

  const StatusCreated({
    required this.type,
    required this.content,
    this.mediaUrl,
    this.bgColor,
  });

  @override
  List<Object?> get props => [type, content, mediaUrl, bgColor];
}

/// Mark a status as viewed by the current user.
class StatusViewed extends StatusEvent {
  final String statusId;

  const StatusViewed({required this.statusId});

  @override
  List<Object?> get props => [statusId];
}

/// User tapped on a contact's status to start viewing.
class StatusSelected extends StatusEvent {
  final String userId;

  const StatusSelected({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Dismiss the status viewer.
class StatusDismissed extends StatusEvent {
  const StatusDismissed();
}

/// ─── Status type ────────────────────────────────────────────────

enum StatusType {
  text,
  image,
  video,
}
