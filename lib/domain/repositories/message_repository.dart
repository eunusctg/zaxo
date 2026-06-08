import 'package:zaxo/domain/entities/message.dart';

abstract class MessageRepository {
  /// Get messages for a specific chat.
  Future<List<Message>> getMessages({required String chatId});

  /// Watch messages for a specific chat in real-time.
  Stream<List<Message>> watchMessages({required String chatId});

  /// Send a message in a chat.
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
  });

  /// Delete a message.
  Future<void> deleteMessage(String messageId);

  /// Toggle the starred state of a message.
  Future<void> toggleStarMessage({
    required String messageId,
    required bool isStarred,
  });

  /// Update the delivery/read status of a message.
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  });
}
