import '../../domain/entities/message.dart' as entity;
import '../../domain/entities/message.dart' show MessageType, MessageStatus;

/// Data model for Message with JSON serialization support.
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final String? replyToId;
  final bool isStarred;
  final bool isDeleted;
  final MessageStatus status;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.type = MessageType.text,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.replyToId,
    this.isStarred = false,
    this.isDeleted = false,
    this.status = MessageStatus.sent,
    required this.createdAt,
  });

  /// Helper getter: checks if this message was sent by the current user.
  bool isMine(String currentUserId) => senderId == currentUserId;

  /// Parse MessageType from string.
  static MessageType parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'video':
        return MessageType.video;
      case 'document':
        return MessageType.document;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      default:
        return MessageType.text;
    }
  }

  /// Parse MessageStatus from string.
  static MessageStatus parseMessageStatus(String? status) {
    switch (status) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }

  /// Convert MessageType to string.
  static String messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      case MessageType.video:
        return 'video';
      case MessageType.document:
        return 'document';
      case MessageType.location:
        return 'location';
      case MessageType.contact:
        return 'contact';
    }
  }

  /// Convert MessageStatus to string.
  static String messageStatusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  /// Create a MessageModel from a JSON map.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      type: parseMessageType(json['type'] as String?),
      content: json['content'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      replyToId: json['replyToId'] as String?,
      isStarred: json['isStarred'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      status: parseMessageStatus(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert this MessageModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'type': messageTypeToString(type),
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'replyToId': replyToId,
      'isStarred': isStarred,
      'isDeleted': isDeleted,
      'status': messageStatusToString(status),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a MessageModel from a domain Message entity.
  factory MessageModel.fromEntity(entity.Message message) {
    return MessageModel(
      id: message.id,
      chatId: message.chatId,
      senderId: message.senderId,
      type: message.type,
      content: message.content,
      mediaUrl: message.mediaUrl,
      mediaType: message.mediaType,
      replyToId: message.replyToId,
      isStarred: message.isStarred,
      isDeleted: message.isDeleted,
      status: message.status,
      createdAt: message.createdAt,
    );
  }

  /// Convert this MessageModel to a domain Message entity.
  entity.Message toEntity() {
    return entity.Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      replyToId: replyToId,
      isStarred: isStarred,
      isDeleted: isDeleted,
      status: status,
      createdAt: createdAt,
    );
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    MessageType? type,
    String? content,
    String? mediaUrl,
    String? mediaType,
    String? replyToId,
    bool? isStarred,
    bool? isDeleted,
    MessageStatus? status,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      replyToId: replyToId ?? this.replyToId,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
