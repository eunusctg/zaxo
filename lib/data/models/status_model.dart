/// Enum for status types in Zaxo.
enum StatusType { text, image, video }

/// Data model for Status (stories) with JSON serialization support.
class StatusModel {
  final String id;
  final String userId;
  final StatusType type;
  final String? mediaUrl;
  final String? caption;
  final String? text;
  final String? bgColor;
  final String? font;
  final DateTime expiresAt;
  final DateTime createdAt;
  final List<String> viewers;

  const StatusModel({
    required this.id,
    required this.userId,
    this.type = StatusType.text,
    this.mediaUrl,
    this.caption,
    this.text,
    this.bgColor,
    this.font,
    required this.expiresAt,
    required this.createdAt,
    this.viewers = const [],
  });

  /// Parse StatusType from string.
  static StatusType parseStatusType(String? type) {
    switch (type) {
      case 'text':
        return StatusType.text;
      case 'image':
        return StatusType.image;
      case 'video':
        return StatusType.video;
      default:
        return StatusType.text;
    }
  }

  /// Convert StatusType to string.
  static String statusTypeToString(StatusType type) {
    switch (type) {
      case StatusType.text:
        return 'text';
      case StatusType.image:
        return 'image';
      case StatusType.video:
        return 'video';
    }
  }

  /// Check if this status has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if a user has viewed this status.
  bool hasViewed(String userId) => viewers.contains(userId);

  /// Create a StatusModel from a JSON map.
  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: parseStatusType(json['type'] as String?),
      mediaUrl: json['mediaUrl'] as String?,
      caption: json['caption'] as String?,
      text: json['text'] as String?,
      bgColor: json['bgColor'] as String?,
      font: json['font'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      viewers: json['viewers'] != null
          ? List<String>.from(json['viewers'] as List)
          : [],
    );
  }

  /// Convert this StatusModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': statusTypeToString(type),
      'mediaUrl': mediaUrl,
      'caption': caption,
      'text': text,
      'bgColor': bgColor,
      'font': font,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'viewers': viewers,
    };
  }

  StatusModel copyWith({
    String? id,
    String? userId,
    StatusType? type,
    String? mediaUrl,
    String? caption,
    String? text,
    String? bgColor,
    String? font,
    DateTime? expiresAt,
    DateTime? createdAt,
    List<String>? viewers,
  }) {
    return StatusModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      caption: caption ?? this.caption,
      text: text ?? this.text,
      bgColor: bgColor ?? this.bgColor,
      font: font ?? this.font,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      viewers: viewers ?? this.viewers,
    );
  }
}
