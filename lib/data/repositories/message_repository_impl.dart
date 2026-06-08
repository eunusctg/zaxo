import 'dart:async';
import '../../domain/entities/message.dart';
import '../../domain/entities/message.dart' show MessageType;
import '../models/message_model.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/remote/api_datasource.dart';
import '../datasources/remote/firebase_datasource.dart';

/// Implementation of MessageRepository that combines API + Firebase + Hive.
/// 
/// Strategy:
/// - getMessages(): Tries cache first, then API, updates cache
/// - getMessagesStream(): Firebase real-time
/// - sendMessage(): API + Firebase + cache update
/// - deleteMessage/starMessage(): API + Firebase + cache update
class MessageRepositoryImpl {
  final ApiDataSource _apiDataSource;
  final FirebaseDataSource _firebaseDataSource;
  final HiveDataSource _hiveDataSource;

  MessageRepositoryImpl({
    required ApiDataSource apiDataSource,
    required FirebaseDataSource firebaseDataSource,
    required HiveDataSource hiveDataSource,
  })  : _apiDataSource = apiDataSource,
        _firebaseDataSource = firebaseDataSource,
        _hiveDataSource = hiveDataSource;

  // ─── Get Messages (Cache-first strategy) ──────────────────────────────────

  /// Get messages for a specific chat using a cache-first strategy:
  /// 1. Return cached messages immediately if available
  /// 2. Fetch from API in the background
  /// 3. Update cache with fresh data
  Future<List<Message>> getMessages(String chatId) async {
    // Step 1: Try to get messages from cache
    final cachedMessages = _hiveDataSource.getCachedMessages(chatId);
    if (cachedMessages.isNotEmpty) {
      // Return cached data while fetching fresh data in the background
      _fetchAndCacheMessages(chatId);
      return cachedMessages.map((model) => model.toEntity()).toList();
    }

    // Step 2: If no cache, fetch from API
    try {
      final apiMessages = await _apiDataSource.getMessages(chatId);
      // Step 3: Update cache
      await _hiveDataSource.cacheMessages(chatId, apiMessages);
      // Step 4: Save sync timestamp
      await _hiveDataSource.saveLastSync('messages_$chatId', DateTime.now());
      return apiMessages.map((model) => model.toEntity()).toList();
    } catch (e) {
      // If API fails, return whatever is in cache (even if empty)
      return cachedMessages.map((model) => model.toEntity()).toList();
    }
  }

  /// Fetch messages from API and update cache (background operation).
  Future<void> _fetchAndCacheMessages(String chatId) async {
    try {
      final apiMessages = await _apiDataSource.getMessages(chatId);
      await _hiveDataSource.cacheMessages(chatId, apiMessages);
      await _hiveDataSource.saveLastSync('messages_$chatId', DateTime.now());
    } catch (_) {
      // Silently fail - cache will be used
    }
  }

  // ─── Real-time Message Stream ─────────────────────────────────────────────

  /// Get a real-time stream of messages for a specific chat using Firebase.
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firebaseDataSource.messagesStream(chatId).map((messageModels) {
      // Update cache whenever we get new data from Firebase
      _hiveDataSource.cacheMessages(chatId, messageModels);
      return messageModels.map((model) => model.toEntity()).toList();
    });
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  /// Send a message to a specific chat.
  /// Sends via API and Firebase, then updates cache.
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
    String? replyToId,
  }) async {
    // Determine the current user ID from Firebase
    final currentUserId = _firebaseDataSource.currentUser?.uid ?? '';
    final messageType = MessageModel.parseMessageType(type);

    // Create the message data map for Firebase
    final messageData = <String, dynamic>{
      'senderId': currentUserId,
      'content': content,
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (replyToId != null) 'replyToId': replyToId,
    };

    // Send via Firebase for real-time sync
    final firebaseMessage = await _firebaseDataSource.sendMessage(
      chatId,
      messageData,
    );

    // Also send via API for persistence
    try {
      final apiMessage = await _apiDataSource.sendMessage(
        chatId: chatId,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        replyToId: replyToId,
      );

      // Update cache with the API response (most authoritative)
      await _hiveDataSource.cacheMessage(chatId, apiMessage);

      return apiMessage.toEntity();
    } catch (e) {
      // If API fails, still return the Firebase message
      await _hiveDataSource.cacheMessage(chatId, firebaseMessage);
      return firebaseMessage.toEntity();
    }
  }

  // ─── Delete Message ───────────────────────────────────────────────────────

  /// Delete a message (soft delete).
  Future<void> deleteMessage(String chatId, String messageId) async {
    // Delete via API
    await _apiDataSource.deleteMessage(chatId, messageId);

    // Delete via Firebase
    await _firebaseDataSource.deleteMessage(chatId, messageId);

    // Update cache - remove or mark as deleted
    await _hiveDataSource.removeCachedMessage(chatId, messageId);
  }

  // ─── Star Message ─────────────────────────────────────────────────────────

  /// Star or unstar a message.
  Future<void> starMessage(String chatId, String messageId, bool isStarred) async {
    // Star via API
    await _apiDataSource.starMessage(chatId, messageId);

    // Star via Firebase
    await _firebaseDataSource.toggleStarMessage(chatId, messageId, isStarred);

    // Update cache
    final cachedMessages = _hiveDataSource.getCachedMessages(chatId);
    final index = cachedMessages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      final updatedMessage = cachedMessages[index].copyWith(isStarred: isStarred);
      cachedMessages[index] = updatedMessage;
      await _hiveDataSource.cacheMessages(chatId, cachedMessages);
    }
  }

  // ─── Update Message Status ────────────────────────────────────────────────

  /// Update the status of a message (sent → delivered → read).
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    // Update via Firebase for real-time
    await _firebaseDataSource.updateMessageStatus(chatId, messageId, status);

    // Update cache
    final cachedMessages = _hiveDataSource.getCachedMessages(chatId);
    final index = cachedMessages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      final parsedStatus = MessageModel.parseMessageStatus(status);
      final updatedMessage = cachedMessages[index].copyWith(status: parsedStatus);
      cachedMessages[index] = updatedMessage;
      await _hiveDataSource.cacheMessages(chatId, cachedMessages);
    }
  }

  // ─── Get Starred Messages ─────────────────────────────────────────────────

  /// Get all starred messages for a specific chat from cache.
  Future<List<Message>> getStarredMessages(String chatId) async {
    final cachedMessages = _hiveDataSource.getCachedMessages(chatId);
    return cachedMessages
        .where((m) => m.isStarred && !m.isDeleted)
        .map((model) => model.toEntity())
        .toList();
  }

  // ─── Search Messages ──────────────────────────────────────────────────────

  /// Search messages in a chat by query string.
  Future<List<Message>> searchMessages(String chatId, String query) async {
    final cachedMessages = _hiveDataSource.getCachedMessages(chatId);
    final queryLower = query.toLowerCase();

    final filteredMessages = cachedMessages
        .where((m) =>
            !m.isDeleted &&
            m.content.toLowerCase().contains(queryLower))
        .toList();

    return filteredMessages.map((model) => model.toEntity()).toList();
  }

  // ─── Load More Messages (Pagination) ──────────────────────────────────────

  /// Load more messages from the API (pagination support).
  Future<List<Message>> loadMoreMessages(
    String chatId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final apiMessages = await _apiDataSource.getMessages(
        chatId,
        page: page,
        limit: limit,
      );

      // Merge with cached messages (avoid duplicates)
      final cachedMessages = _hiveDataSource.getCachedMessages(chatId);
      final cachedIds = cachedMessages.map((m) => m.id).toSet();

      final newMessages = apiMessages.where((m) => !cachedIds.contains(m.id)).toList();
      final allMessages = [...cachedMessages, ...newMessages];

      // Sort by creation time
      allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Update cache
      await _hiveDataSource.cacheMessages(chatId, allMessages);

      return allMessages.map((model) => model.toEntity()).toList();
    } catch (e) {
      // If API fails, return cached messages
      final cachedMessages = _hiveDataSource.getCachedMessages(chatId);
      return cachedMessages.map((model) => model.toEntity()).toList();
    }
  }

  // ─── Clear Message Cache ──────────────────────────────────────────────────

  /// Clear cached messages for a specific chat.
  Future<void> clearMessageCache(String chatId) async {
    await _hiveDataSource.clearChatMessages(chatId);
  }

  /// Clear all message caches.
  Future<void> clearAllMessageCache() async {
    await _hiveDataSource.clearMessagesCache();
  }
}
