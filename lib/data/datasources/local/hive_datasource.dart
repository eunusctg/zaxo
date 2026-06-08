import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';

/// Local data source that manages Hive-based caching for chats and messages.
class HiveDataSource {
  static const String _chatsBoxName = 'zaxo_chats';
  static const String _messagesBoxName = 'zaxo_messages';
  static const String _settingsBoxName = 'zaxo_settings';

  Box<String>? _chatsBox;
  Box<String>? _messagesBox;
  Box<dynamic>? _settingsBox;

  /// Initialize Hive boxes for caching.
  Future<void> init() async {
    _chatsBox = await Hive.openBox<String>(_chatsBoxName);
    _messagesBox = await Hive.openBox<String>(_messagesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  /// Ensure boxes are initialized before access.
  void _ensureInitialized() {
    if (_chatsBox == null || _messagesBox == null || _settingsBox == null) {
      throw StateError(
        'HiveDataSource not initialized. Call init() first.',
      );
    }
  }

  // ─── Chat Caching ─────────────────────────────────────────────────────────

  /// Cache a list of chats to local storage.
  Future<void> cacheChats(List<ChatModel> chats) async {
    _ensureInitialized();
    final jsonList = chats.map((chat) => jsonEncode(chat.toJson())).toList();
    await _chatsBox!.put('chats', jsonEncode(jsonList));
  }

  /// Retrieve cached chats from local storage.
  List<ChatModel> getCachedChats() {
    _ensureInitialized();
    final raw = _chatsBox!.get('chats');
    if (raw == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .map((item) => ChatModel.fromJson(jsonDecode(item as String) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If cache is corrupted, return empty list
      return [];
    }
  }

  // ─── Message Caching ──────────────────────────────────────────────────────

  /// Cache messages for a specific chat.
  Future<void> cacheMessages(String chatId, List<MessageModel> messages) async {
    _ensureInitialized();
    final jsonList = messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await _messagesBox!.put('messages_$chatId', jsonEncode(jsonList));
  }

  /// Retrieve cached messages for a specific chat.
  List<MessageModel> getCachedMessages(String chatId) {
    _ensureInitialized();
    final raw = _messagesBox!.get('messages_$chatId');
    if (raw == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .map((item) => MessageModel.fromJson(jsonDecode(item as String) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If cache is corrupted, return empty list
      return [];
    }
  }

  // ─── Single Chat Caching ──────────────────────────────────────────────────

  /// Cache or update a single chat.
  Future<void> cacheChat(ChatModel chat) async {
    _ensureInitialized();
    final chats = getCachedChats();
    final index = chats.indexWhere((c) => c.id == chat.id);
    if (index >= 0) {
      chats[index] = chat;
    } else {
      chats.add(chat);
    }
    await cacheChats(chats);
  }

  /// Remove a chat from cache.
  Future<void> removeCachedChat(String chatId) async {
    _ensureInitialized();
    final chats = getCachedChats();
    chats.removeWhere((c) => c.id == chatId);
    await cacheChats(chats);
    await _messagesBox!.delete('messages_$chatId');
  }

  // ─── Single Message Caching ───────────────────────────────────────────────

  /// Cache or update a single message within a chat.
  Future<void> cacheMessage(String chatId, MessageModel message) async {
    _ensureInitialized();
    final messages = getCachedMessages(chatId);
    final index = messages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
    await cacheMessages(chatId, messages);
  }

  /// Remove a message from cache.
  Future<void> removeCachedMessage(String chatId, String messageId) async {
    _ensureInitialized();
    final messages = getCachedMessages(chatId);
    messages.removeWhere((m) => m.id == messageId);
    await cacheMessages(chatId, messages);
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  /// Save a setting value.
  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();
    await _settingsBox!.put(key, value);
  }

  /// Get a setting value.
  T? getSetting<T>(String key) {
    _ensureInitialized();
    return _settingsBox!.get(key) as T?;
  }

  // ─── Cache Management ─────────────────────────────────────────────────────

  /// Clear all cached data (chats, messages, and settings).
  Future<void> clearCache() async {
    _ensureInitialized();
    await _chatsBox!.clear();
    await _messagesBox!.clear();
    await _settingsBox!.clear();
  }

  /// Clear only cached messages (keep chats and settings).
  Future<void> clearMessagesCache() async {
    _ensureInitialized();
    await _messagesBox!.clear();
  }

  /// Clear cached messages for a specific chat.
  Future<void> clearChatMessages(String chatId) async {
    _ensureInitialized();
    await _messagesBox!.delete('messages_$chatId');
  }

  /// Get the last sync timestamp for a given key.
  DateTime? getLastSync(String key) {
    _ensureInitialized();
    final timestamp = _settingsBox!.get('lastSync_$key') as String?;
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Save the last sync timestamp for a given key.
  Future<void> saveLastSync(String key, DateTime timestamp) async {
    _ensureInitialized();
    await _settingsBox!.put('lastSync_$key', timestamp.toIso8601String());
  }

  /// Dispose of all Hive boxes.
  Future<void> dispose() async {
    await _chatsBox?.close();
    await _messagesBox?.close();
    await _settingsBox?.close();
    _chatsBox = null;
    _messagesBox = null;
    _settingsBox = null;
  }
}
