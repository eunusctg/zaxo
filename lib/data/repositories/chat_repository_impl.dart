import 'dart:async';
import '../../domain/entities/chat.dart';
import '../../domain/entities/user.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/remote/api_datasource.dart';
import '../datasources/remote/firebase_datasource.dart';

/// Implementation of ChatRepository that combines API + Firebase + Hive.
/// 
/// Strategy:
/// - getChats(): Tries cache first, then API, updates cache
/// - getChatStream(): Firebase real-time
/// - createChat/deleteChat/archiveChat/pinChat(): API + cache update
class ChatRepositoryImpl {
  final ApiDataSource _apiDataSource;
  final FirebaseDataSource _firebaseDataSource;
  final HiveDataSource _hiveDataSource;

  ChatRepositoryImpl({
    required ApiDataSource apiDataSource,
    required FirebaseDataSource firebaseDataSource,
    required HiveDataSource hiveDataSource,
  })  : _apiDataSource = apiDataSource,
        _firebaseDataSource = firebaseDataSource,
        _hiveDataSource = hiveDataSource;

  // ─── Get Chats (Cache-first strategy) ─────────────────────────────────────

  /// Get chats using a cache-first strategy:
  /// 1. Return cached chats immediately if available
  /// 2. Fetch from API in the background
  /// 3. Update cache with fresh data
  Future<List<Chat>> getChats() async {
    // Step 1: Try to get chats from cache
    final cachedChats = _hiveDataSource.getCachedChats();
    if (cachedChats.isNotEmpty) {
      // Return cached data while fetching fresh data in the background
      _fetchAndCacheChats();
      return cachedChats.map((model) => model.toEntity()).toList();
    }

    // Step 2: If no cache, fetch from API
    try {
      final apiChats = await _apiDataSource.getChats();
      // Step 3: Update cache
      await _hiveDataSource.cacheChats(apiChats);
      // Step 4: Save sync timestamp
      await _hiveDataSource.saveLastSync('chats', DateTime.now());
      return apiChats.map((model) => model.toEntity()).toList();
    } catch (e) {
      // If API fails, return whatever is in cache (even if empty)
      return cachedChats.map((model) => model.toEntity()).toList();
    }
  }

  /// Fetch chats from API and update cache (background operation).
  Future<void> _fetchAndCacheChats() async {
    try {
      final apiChats = await _apiDataSource.getChats();
      await _hiveDataSource.cacheChats(apiChats);
      await _hiveDataSource.saveLastSync('chats', DateTime.now());
    } catch (_) {
      // Silently fail - cache will be used
    }
  }

  // ─── Real-time Chat Stream ────────────────────────────────────────────────

  /// Get a real-time stream of chats using Firebase Firestore.
  Stream<List<Chat>> getChatStream(String userId) {
    return _firebaseDataSource.chatsStream(userId).map((chatModels) {
      // Update cache whenever we get new data from Firebase
      _hiveDataSource.cacheChats(chatModels);
      return chatModels.map((model) => model.toEntity()).toList();
    });
  }

  // ─── Create Chat ──────────────────────────────────────────────────────────

  /// Create a new chat (direct or group).
  /// Creates via API, then updates cache.
  Future<Chat> createChat({
    required List<String> participantIds,
    bool isGroup = false,
    String? groupName,
  }) async {
    // Create via API
    final chatModel = await _apiDataSource.createChat(
      participantIds: participantIds,
      isGroup: isGroup,
      groupName: groupName,
    );

    // Also create in Firebase for real-time sync
    await _firebaseDataSource.createChat(
      participantIds: participantIds,
      isGroup: isGroup,
      groupName: groupName,
    );

    // Update cache
    await _hiveDataSource.cacheChat(chatModel);

    return chatModel.toEntity();
  }

  // ─── Delete Chat ──────────────────────────────────────────────────────────

  /// Delete a chat by ID.
  /// Deletes from API and Firebase, then removes from cache.
  Future<void> deleteChat(String chatId) async {
    // Delete via API
    await _apiDataSource.deleteChat(chatId);

    // Delete from Firebase
    await _firebaseDataSource.deleteChat(chatId);

    // Remove from cache
    await _hiveDataSource.removeCachedChat(chatId);
  }

  // ─── Archive Chat ─────────────────────────────────────────────────────────

  /// Archive a chat by ID.
  Future<void> archiveChat(String chatId) async {
    // Archive via API
    await _apiDataSource.archiveChat(chatId);

    // Update cache - mark as archived or remove from active chats
    final cachedChats = _hiveDataSource.getCachedChats();
    final updatedChats = cachedChats.where((c) => c.id != chatId).toList();
    await _hiveDataSource.cacheChats(updatedChats);
  }

  // ─── Pin Chat ─────────────────────────────────────────────────────────────

  /// Pin a chat by ID.
  Future<void> pinChat(String chatId) async {
    // Pin via API
    await _apiDataSource.pinChat(chatId);

    // Update cache - move pinned chat to top
    final cachedChats = _hiveDataSource.getCachedChats();
    // Note: In a full implementation, we'd add a `isPinned` field
    // and sort accordingly. For now, just refresh from API.
    await _fetchAndCacheChats();
  }

  // ─── Search Chats ─────────────────────────────────────────────────────────

  /// Search chats by query string.
  Future<List<Chat>> searchChats(String query) async {
    // Search through cached chats first
    final cachedChats = _hiveDataSource.getCachedChats();
    final queryLower = query.toLowerCase();

    final filteredChats = cachedChats.where((chat) {
      if (chat.isGroup && chat.groupName != null) {
        return chat.groupName!.toLowerCase().contains(queryLower);
      }
      return chat.participants.any(
        (p) => p.name.toLowerCase().contains(queryLower),
      );
    }).toList();

    return filteredChats.map((model) => model.toEntity()).toList();
  }

  // ─── Get Chat by ID ───────────────────────────────────────────────────────

  /// Get a single chat by ID from cache or API.
  Future<Chat?> getChatById(String chatId) async {
    // Try cache first
    final cachedChats = _hiveDataSource.getCachedChats();
    final cachedChat = cachedChats.where((c) => c.id == chatId).firstOrNull;
    if (cachedChat != null) {
      return cachedChat.toEntity();
    }

    // If not in cache, fetch all chats from API and look for it
    try {
      final apiChats = await _apiDataSource.getChats();
      await _hiveDataSource.cacheChats(apiChats);
      final apiChat = apiChats.where((c) => c.id == chatId).firstOrNull;
      return apiChat?.toEntity();
    } catch (e) {
      return null;
    }
  }

  // ─── Update Chat Participants ─────────────────────────────────────────────

  /// Fetch and populate participant details for a chat.
  Future<Chat> getChatWithParticipants(Chat chat) async {
    try {
      final participants = await _firebaseDataSource.fetchParticipants(
        chat.participants.map((p) => p.id).toList(),
      );
      return chat.copyWith(
        participants: participants.map((p) => p.toEntity()).toList(),
      );
    } catch (e) {
      return chat;
    }
  }

  // ─── Clear Chat Cache ─────────────────────────────────────────────────────

  /// Clear all cached chats.
  Future<void> clearChatCache() async {
    await _hiveDataSource.clearCache();
  }
}
