import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/message.dart';

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any messages are loaded.
class MessageInitial extends MessageState {
  const MessageInitial();
}

/// Messages are loading.
class MessageLoading extends MessageState {
  const MessageLoading();
}

/// Messages loaded successfully.
class MessageLoaded extends MessageState {
  /// The list of messages for the current chat, ordered chronologically.
  final List<Message> messages;

  /// The ID of the chat whose messages are loaded.
  final String chatId;

  const MessageLoaded({
    required this.messages,
    required this.chatId,
  });

  /// Convenience getter for starred messages.
  List<Message> get starredMessages =>
      messages.where((m) => m.isStarred).toList();

  MessageLoaded copyWith({
    List<Message>? messages,
    String? chatId,
  }) {
    return MessageLoaded(
      messages: messages ?? this.messages,
      chatId: chatId ?? this.chatId,
    );
  }

  @override
  List<Object?> get props => [messages, chatId];
}

/// A message is currently being sent (optimistic UI update).
class MessageSending extends MessageState {
  /// The list of messages including the optimistically added one.
  final List<Message> messages;

  /// The ID of the current chat.
  final String chatId;

  const MessageSending({
    required this.messages,
    required this.chatId,
  });

  @override
  List<Object?> get props => [messages, chatId];
}

/// An error occurred during a message operation.
class MessageError extends MessageState {
  final String message;

  const MessageError(this.message);

  @override
  List<Object?> get props => [message];
}
