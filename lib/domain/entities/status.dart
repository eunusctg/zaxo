import 'package:equatable/equatable.dart';

/// Type of status content.
enum StatusMediaType {
  text,
  image,
  video,
}

class Status extends Equatable {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final StatusMediaType type;
  final String? mediaUrl;
  final String? caption;
  final String? text;
  final String? bgColor;
  final String? font;
  final bool isViewedByMe;
  final int viewCount;
  final List<String> viewers;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Status({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    this.type = StatusMediaType.text,
    this.mediaUrl,
    this.caption,
    this.text,
    this.bgColor,
    this.font,
    this.isViewedByMe = false,
    this.viewCount = 0,
    this.viewers = const [],
    required this.createdAt,
    required this.expiresAt,
  });

  /// The main content string: text for text statuses, caption for media.
  String get content => text ?? caption ?? '';

  /// Whether this status has expired (24-hour window).
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Status copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    StatusMediaType? type,
    String? mediaUrl,
    String? caption,
    String? text,
    String? bgColor,
    String? font,
    bool? isViewedByMe,
    int? viewCount,
    List<String>? viewers,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Status(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      caption: caption ?? this.caption,
      text: text ?? this.text,
      bgColor: bgColor ?? this.bgColor,
      font: font ?? this.font,
      isViewedByMe: isViewedByMe ?? this.isViewedByMe,
      viewCount: viewCount ?? this.viewCount,
      viewers: viewers ?? this.viewers,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhotoUrl,
        type,
        mediaUrl,
        caption,
        text,
        bgColor,
        font,
        isViewedByMe,
        viewCount,
        viewers,
        createdAt,
        expiresAt,
      ];
}
