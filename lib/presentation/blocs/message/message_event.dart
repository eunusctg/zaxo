import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/message.dart' show MessageType, MessageStatus;

abstract class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object?> get props => [];
}

/// Load messages for a specific chat.
class MessageLoadRequested extends MessageEvent {
  final String chatId;

  const MessageLoadRequested({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

/// Send a message in a chat.
class MessageSent extends MessageEvent {
  final String chatId;
  final String content;
  final MessageType type;
  final String? replyToId;

  const MessageSent({
    required this.chatId,
    required this.content,
    this.type = MessageType.text,
    this.replyToId,
  });

  @override
  List<Object?> get props => [chatId, content, type, replyToId];
}

/// Delete a message.
class MessageDeleted extends MessageEvent {
  final String messageId;

  const MessageDeleted({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

/// Star or unstar a message.
class MessageStarred extends MessageEvent {
  final String messageId;

  const MessageStarred({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

/// Update the delivery/read status of a message.
class MessageStatusUpdated extends MessageEvent {
  final String messageId;
  final MessageStatus status;

  const MessageStatusUpdated({
    required this.messageId,
    required this.status,
  });

  @override
  List<Object?> get props => [messageId, status];
}
