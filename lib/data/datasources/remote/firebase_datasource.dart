import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:zaxo/domain/entities/user.dart' as domain;
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

/// Abstract interface for Firebase data operations.
abstract class FirebaseDataSource {
  /// Get the current Firebase user.
  fb_auth.User? get currentUser;

  Future<void> createUserDocument(domain.User user);
  Future<void> updateUserOnlineStatus(String userId, {required bool isOnline});
  Future<domain.User?> getUserDocument(String userId);
  Future<List<UserModel>> fetchParticipants(List<String> userIds);
  Stream<List<ChatModel>> chatsStream(String userId);
  Future<void> createChat({required List<String> participantIds, required bool isGroup, String? groupName});
  Future<void> deleteChat(String chatId);
  Future<void> archiveChat(String chatId);
  Future<void> pinChat(String chatId);
  Stream<List<MessageModel>> messagesStream(String chatId);
  Future<MessageModel> sendMessage(String chatId, Map<String, dynamic> messageData);
  Future<void> deleteMessage(String chatId, String messageId);
  Future<void> toggleStarMessage(String chatId, String messageId, bool isStarred);
  Future<void> updateMessageStatus(String chatId, String messageId, String status);
}
