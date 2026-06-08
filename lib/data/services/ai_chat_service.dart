/// Service class for AI-powered chat via the Zaxo Next.js backend.
///
/// Sends user messages and conversation history to the `/api/zaxo/ai-chat`
/// endpoint and returns the AI-generated response.
library;

import 'package:dio/dio.dart';

/// Communicates with the Zaxo AI chat backend.
///
/// The backend runs as a Next.js server at the configured [baseUrl]. For
/// Android emulator development, the default `http://10.0.2.2:3000` maps
/// to the host machine's `localhost:3000`.
///
/// ### Endpoint
/// `POST /api/zaxo/ai-chat`
///
/// ### Request body
/// ```json
/// {
///   "message": "Hello!",
///   "history": [
///     {"role": "user", "content": "Hi"},
///     {"role": "assistant", "content": "Hello! How can I help?"}
///   ]
/// }
/// ```
///
/// ### Response body
/// ```json
/// {
///   "response": "I'm doing great, thanks for asking!"
/// }
/// ```
class AiChatService {
  // ── Constructor ────────────────────────────────────────────────────────

  AiChatService({
    String? baseUrl,
    Dio? dio,
  })  : _baseUrl = baseUrl ?? 'http://10.0.2.2:3000',
        _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ));

  /// Base URL of the Next.js backend server.
  ///
  /// Defaults to `http://10.0.2.2:3000` (Android emulator localhost).
  /// Override for physical devices or production:
  /// ```dart
  /// AiChatService(baseUrl: 'https://zaxo.eu.cc')
  /// ```
  final String _baseUrl;

  final Dio _dio;

  /// Full endpoint URL for the AI chat API.
  String get _endpoint => '$_baseUrl/api/zaxo/ai-chat';

  // ═══════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════

  /// Sends a [message] to the AI chat endpoint and returns the response.
  ///
  /// [message] – The user's current message text.
  /// [history] – Prior conversation turns for context. Each map should
  ///   contain `role` (`"user"` or `"assistant"`) and `content` (String).
  ///
  /// Returns the AI assistant's reply text.
  ///
  /// Throws [AiChatException] on network or server errors.
  Future<String> sendMessage(
    String message,
    List<Map<String, dynamic>> history,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: {
          'message': message,
          'history': history,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const AiChatException('Empty response from AI chat server.');
      }

      // The backend may return the text under `response` or `reply`.
      final aiResponse = data['response'] as String? ??
          data['reply'] as String? ??
          data['message'] as String?;

      if (aiResponse == null || aiResponse.isEmpty) {
        throw const AiChatException(
          'AI chat server returned an empty response.',
        );
      }

      return aiResponse;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw const AiChatException(
            'AI chat request timed out. Please try again.',
          );
        case DioExceptionType.connectionError:
          throw const AiChatException(
            'Could not connect to the AI chat server. '
            'Check your network connection.',
          );
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          throw AiChatException(
            'AI chat server returned error $statusCode: '
            '${e.response?.statusMessage ?? 'Unknown error'}',
          );
        default:
          throw AiChatException('Network error: ${e.message}');
      }
    } on AiChatException {
      rethrow;
    } catch (e) {
      throw AiChatException('Unexpected error: $e');
    }
  }

  /// Convenience method to send a message without prior history.
  ///
  /// Equivalent to `sendMessage(message, [])`.
  Future<String> sendSimpleMessage(String message) {
    return sendMessage(message, []);
  }

  /// Checks if the AI chat server is reachable.
  ///
  /// Returns `true` if the server responds to a GET request.
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get<String>(
        _baseUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode != null && response.statusCode! < 500;
    } catch (_) {
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  EXCEPTION
// ═══════════════════════════════════════════════════════════════════════════

/// Exception thrown by [AiChatService] on errors.
class AiChatException implements Exception {
  final String message;
  const AiChatException(this.message);

  @override
  String toString() => 'AiChatException: $message';
}
