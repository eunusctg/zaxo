import 'package:dio/dio.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/call_model.dart';
import '../../models/status_model.dart';

/// Remote API data source using Dio for REST API communication.
class ApiDataSource {
  static const String baseUrl = 'https://zaxo.eu.cc/api';

  late final Dio _dio;

  ApiDataSource({Dio? dio, String? token}) {
    _dio = dio ?? Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  /// Update the authorization token.
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear the authorization token.
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  /// Sign up a new user.
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'name': name,
      },
    );
    return response.data!;
  }

  /// Sign in an existing user.
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/signin',
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data!;
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  /// Get the current user's profile.
  Future<UserModel> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/user/profile');
    return UserModel.fromJson(response.data!);
  }

  /// Update the current user's profile.
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/user/profile',
      data: data,
    );
    return UserModel.fromJson(response.data!);
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  /// Search for users by query string.
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _dio.get<List<dynamic>>(
      '/users/search',
      queryParameters: {'q': query},
    );
    return (response.data ?? [])
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Chats ────────────────────────────────────────────────────────────────

  /// Get all chats for the current user.
  Future<List<ChatModel>> getChats() async {
    final response = await _dio.get<List<dynamic>>('/chats');
    return (response.data ?? [])
        .map((json) => ChatModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new chat (direct or group).
  Future<ChatModel> createChat({
    required List<String> participantIds,
    bool isGroup = false,
    String? groupName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chats',
      data: {
        'participantIds': participantIds,
        'isGroup': isGroup,
        if (groupName != null) 'groupName': groupName,
      },
    );
    return ChatModel.fromJson(response.data!);
  }

  /// Delete a chat by ID.
  Future<void> deleteChat(String chatId) async {
    await _dio.delete('/chats/$chatId');
  }

  /// Archive a chat by ID.
  Future<void> archiveChat(String chatId) async {
    await _dio.put('/chats/$chatId/archive');
  }

  /// Pin a chat by ID.
  Future<void> pinChat(String chatId) async {
    await _dio.put('/chats/$chatId/pin');
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  /// Get messages for a specific chat with pagination.
  Future<List<MessageModel>> getMessages(
    String chatId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/chats/$chatId/messages',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return (response.data ?? [])
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Send a message to a chat.
  Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
    String? replyToId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chats/$chatId/messages',
      data: {
        'content': content,
        'type': type,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (replyToId != null) 'replyToId': replyToId,
      },
    );
    return MessageModel.fromJson(response.data!);
  }

  /// Delete a message by ID.
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _dio.delete('/chats/$chatId/messages/$messageId');
  }

  /// Star a message by ID.
  Future<void> starMessage(String chatId, String messageId) async {
    await _dio.put('/chats/$chatId/messages/$messageId/star');
  }

  // ─── Calls ────────────────────────────────────────────────────────────────

  /// Initiate a call to another user.
  Future<CallModel> initiateCall({
    required String receiverId,
    String type = 'audio',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/calls',
      data: {
        'receiverId': receiverId,
        'type': type,
      },
    );
    return CallModel.fromJson(response.data!);
  }

  /// Get call history.
  Future<List<CallModel>> getCalls() async {
    final response = await _dio.get<List<dynamic>>('/calls');
    return (response.data ?? [])
        .map((json) => CallModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Status ───────────────────────────────────────────────────────────────

  /// Get all statuses from contacts.
  Future<List<StatusModel>> getStatuses() async {
    final response = await _dio.get<List<dynamic>>('/statuses');
    return (response.data ?? [])
        .map((json) => StatusModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new status.
  Future<StatusModel> createStatus({
    required String type,
    required String content,
    String? mediaUrl,
    String? bgColor,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/statuses',
      data: {
        'type': type,
        'content': content,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (bgColor != null) 'bgColor': bgColor,
      },
    );
    return StatusModel.fromJson(response.data!);
  }

  // ─── File Upload ──────────────────────────────────────────────────────────

  /// Upload a file and return the URL.
  Future<String> uploadFile(dynamic file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file is String ? file : file.path as String,
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data!['url'] as String;
  }
}
