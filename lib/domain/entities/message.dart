import 'package:equatable/equatable.dart';

/// Type of message content.
enum MessageType {
  text,
  image,
  voice,
  video,
  document,
  location,
  contact,
}

/// Delivery status of a message.
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message extends Equatable {
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

  const Message({
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
    this.status = MessageStatus.sending,
    required this.createdAt,
  });

  /// Helper getter: checks if this message was sent by the current user.
  bool isMine(String currentUserId) => senderId == currentUserId;

  Message copyWith({
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
    return Message(
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

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        type,
        content,
        mediaUrl,
        mediaType,
        replyToId,
        isStarred,
        isDeleted,
        status,
        createdAt,
      ];
}
