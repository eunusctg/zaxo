import 'package:zaxo/domain/entities/chat.dart';

abstract class ChatRepository {
  /// Get all chats for the current user.
  Future<List<Chat>> getChats();

  /// Watch chats in real-time.
  Stream<List<Chat>> watchChats();

  /// Create a new chat.
  Future<Chat> createChat({
    required List<String> participantIds,
    required bool isGroup,
    String? groupName,
  });

  /// Delete a chat.
  Future<void> deleteChat(String chatId);

  /// Mark a chat as read.
  Future<void> markAsRead(String chatId);

  /// Archive or unarchive a chat.
  Future<void> archiveChat({
    required String chatId,
    required bool isArchived,
  });

  /// Pin or unpin a chat.
  Future<void> pinChat({
    required String chatId,
    required bool isPinned,
  });

  /// Mute or unmute a chat.
  Future<void> muteChat({
    required String chatId,
    required bool isMuted,
  });
}
