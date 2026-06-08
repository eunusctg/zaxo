import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zaxo/data/services/ai_chat_service.dart';
import 'package:zaxo/data/services/firebase_database_service.dart';
import 'package:zaxo/domain/entities/message.dart';

import 'message_event.dart';
import 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final FirebaseDatabaseService _dbService;
  final AiChatService _aiChatService;

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  String? _currentChatId;

  MessageBloc({
    required FirebaseDatabaseService dbService,
    required AiChatService aiChatService,
  })  : _dbService = dbService,
        _aiChatService = aiChatService,
        super(const MessageInitial()) {
    on<MessageLoadRequested>(_onLoadRequested);
    on<MessageSent>(_onSent);
    on<MessageDeleted>(_onDeleted);
    on<MessageStarred>(_onStarred);
    on<MessageStatusUpdated>(_onStatusUpdated);
  }

  // ── Factory: convert Firebase Map to Message entity ────────────────────

  Message _mapToMessage(Map<String, dynamic> data) {
    return Message(
      id: data['id'] as String? ?? '',
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      type: _parseMessageType(data['type'] as String?),
      content: data['content'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
      replyToId: data['replyToId'] as String?,
      isStarred: data['isStarred'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      status: _parseMessageStatus(data['status'] as String?),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'video':
        return MessageType.video;
      case 'document':
        return MessageType.document;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      default:
        return MessageType.text;
    }
  }

  MessageStatus _parseMessageStatus(String? status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sending;
    }
  }

  String _messageStatusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      case MessageType.video:
        return 'video';
      case MessageType.document:
        return 'document';
      case MessageType.location:
        return 'location';
      case MessageType.contact:
        return 'contact';
    }
  }

  // ── Event Handlers ─────────────────────────────────────────────────────

  Future<void> _onLoadRequested(
    MessageLoadRequested event,
    Emitter<MessageState> emit,
  ) async {
    emit(const MessageLoading());

    // Cancel previous subscription if switching chats.
    await _messagesSubscription?.cancel();
    _currentChatId = event.chatId;

    _messagesSubscription = _dbService.getMessages(event.chatId).listen(
      (messageMaps) {
        if (!isClosed) {
          final messages = messageMaps.map(_mapToMessage).toList();
          emit(MessageLoaded(messages: messages, chatId: event.chatId));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(MessageError(error.toString()));
        }
      },
    );
  }

  Future<void> _onSent(MessageSent event, Emitter<MessageState> emit) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final now = DateTime.now().toIso8601String();

    final messageData = <String, dynamic>{
      'chatId': event.chatId,
      'senderId': currentUserId,
      'type': _messageTypeToString(event.type),
      'content': event.content,
      'status': 'sending',
      'isStarred': false,
      'isDeleted': false,
      'createdAt': now,
    };

    if (event.replyToId != null) {
      messageData['replyToId'] = event.replyToId;
    }

    try {
      // Send to Firebase — the real-time stream will pick up the new message.
      final messageId = await _dbService.sendMessage(event.chatId, messageData);

      // Update status to 'sent' after successful write.
      await _dbService.updateMessageStatus(event.chatId, messageId, 'sent');

      // Check if this is an AI chat and get AI response if so.
      await _tryGetAiResponse(event.chatId, event.content);
    } catch (e) {
      emit(MessageError('Failed to send message: $e'));
    }
  }

  /// Attempts to get an AI response for the given chat.
  ///
  /// If the chat is marked as an AI chat (has `isAiChat: true` in the
  /// database), the user's message is forwarded to the AI service and
  /// the response is written back as a new message.
  Future<void> _tryGetAiResponse(String chatId, String userMessage) async {
    try {
      // Send to AI chat service.
      final aiResponse = await _aiChatService.sendSimpleMessage(userMessage);

      // Write AI response as a new message.
      final now = DateTime.now().toIso8601String();
      await _dbService.sendMessage(chatId, {
        'chatId': chatId,
        'senderId': 'ai-assistant',
        'type': 'text',
        'content': aiResponse,
        'status': 'sent',
        'isStarred': false,
        'isDeleted': false,
        'createdAt': now,
      });
    } catch (_) {
      // AI response is best-effort — don't fail the user's send.
    }
  }

  Future<void> _onDeleted(
    MessageDeleted event,
    Emitter<MessageState> emit,
  ) async {
    if (_currentChatId == null) return;
    try {
      // Soft delete in Firebase.
      await _dbService.deleteMessage(_currentChatId!, event.messageId);
    } catch (e) {
      emit(MessageError('Failed to delete message: $e'));
    }
  }

  Future<void> _onStarred(
    MessageStarred event,
    Emitter<MessageState> emit,
  ) async {
    if (_currentChatId == null) return;
    try {
      // Find the current starred state to toggle.
      final currentState = state;
      bool currentlyStarred = false;
      if (currentState is MessageLoaded) {
        final match = currentState.messages.where((m) => m.id == event.messageId);
        if (match.isNotEmpty) {
          currentlyStarred = match.first.isStarred;
        }
      }

      // Toggle star in Firebase using the generic updateMessage method.
      await _dbService.updateMessage(
        _currentChatId!,
        event.messageId,
        {'isStarred': !currentlyStarred},
      );
    } catch (e) {
      emit(MessageError('Failed to star message: $e'));
    }
  }

  Future<void> _onStatusUpdated(
    MessageStatusUpdated event,
    Emitter<MessageState> emit,
  ) async {
    if (_currentChatId == null) return;
    try {
      await _dbService.updateMessageStatus(
        _currentChatId!,
        event.messageId,
        _messageStatusToString(event.status),
      );
    } catch (e) {
      emit(MessageError('Failed to update message status: $e'));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
