import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:zaxo/data/services/firebase_database_service.dart';
import 'package:zaxo/domain/entities/chat.dart';
import 'package:zaxo/domain/entities/message.dart';
import 'package:zaxo/domain/entities/user.dart';

import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FirebaseDatabaseService _dbService;

  StreamSubscription<List<Map<String, dynamic>>>? _chatsSubscription;
  String? _currentUserId;

  ChatBloc({
    required FirebaseDatabaseService dbService,
  })  : _dbService = dbService,
        super(const ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatRefreshed>(_onChatRefreshed);
    on<ChatSelected>(_onChatSelected);
    on<ChatCreated>(_onChatCreated);
    on<ChatDeleted>(_onChatDeleted);
    on<ChatArchived>(_onChatArchived);
    on<ChatPinned>(_onChatPinned);
    on<ChatMuted>(_onChatMuted);
    on<ChatSearchQueryChanged>(_onSearchQueryChanged);
    on<ChatSelectionModeToggled>(_onSelectionModeToggled);
    on<ChatSelectionToggled>(_onSelectionToggled);
  }

  // ── Factory: convert Firebase Map to Chat entity ───────────────────────

  Chat _mapToChat(Map<String, dynamic> data) {
    // Parse participants from Firebase data.
    final participants = <User>[];
    if (data['participants'] is List) {
      for (final p in (data['participants'] as List)) {
        if (p is Map<String, dynamic>) {
          participants.add(_mapToUser(p));
        }
      }
    }

    // Parse lastMessage if present.
    Message? lastMessage;
    if (data['lastMessage'] is Map<String, dynamic>) {
      lastMessage = _mapToMessage(data['lastMessage'] as Map<String, dynamic>);
    }

    // Parse participant IDs for reference.
    final participantIds = <String>[];
    if (data['participantIds'] is List) {
      participantIds.addAll((data['participantIds'] as List).cast<String>());
    }

    // If participants list is empty but participantIds exist,
    // create placeholder User objects.
    if (participants.isEmpty && participantIds.isNotEmpty) {
      for (final id in participantIds) {
        participants.add(User(
          id: id,
          name: data['participantNames'] is List
              ? (data['participantNames'] as List).firstWhere(
                  (n) => true,
                  orElse: () => 'Unknown',
                ) as String
              : 'Unknown',
          email: '',
          createdAt: DateTime.now(),
        ));
      }
    }

    return Chat(
      id: data['id'] as String? ?? '',
      isGroup: data['isGroup'] as bool? ?? false,
      groupName: data['groupName'] as String?,
      groupAvatar: data['groupAvatar'] as String?,
      groupDescription: data['groupDescription'] as String?,
      participants: participants,
      lastMessage: lastMessage,
      lastMessageTime: data['lastMessageTime'] != null
          ? DateTime.tryParse(data['lastMessageTime'] as String)
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
      unreadCount: data['unreadCount'] as int? ?? 0,
      isPinned: data['isPinned'] as bool? ?? false,
      isMuted: data['isMuted'] as bool? ?? false,
      isArchived: data['isArchived'] as bool? ?? false,
    );
  }

  User _mapToUser(Map<String, dynamic> data) {
    return User(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Unknown',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      about: data['about'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: data['lastSeen'] != null
          ? DateTime.tryParse(data['lastSeen'] as String)
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

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

  // ── Event Handlers ─────────────────────────────────────────────────────

  Future<void> _onChatStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());

    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) {
      emit(const ChatLoaded(
        chats: [],
        filteredChats: [],
        selectedChatIds: {},
        searchQuery: '',
        isSelecting: false,
      ));
      return;
    }

    await _chatsSubscription?.cancel();
    _chatsSubscription = _dbService.getChats(_currentUserId!).listen(
      (chatMaps) {
        final chats = chatMaps.map(_mapToChat).toList();
        if (!isClosed) {
          add(ChatRefreshed());
          // Store the raw chats for internal use.
          _latestChats = chats;
          emit(ChatLoaded(
            chats: chats,
            filteredChats: _filterChats(chats, _currentSearchQuery),
            selectedChatIds: const {},
            searchQuery: _currentSearchQuery,
            isSelecting: false,
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(ChatError(error.toString()));
        }
      },
    );
  }

  // Cache for search filtering.
  List<Chat> _latestChats = [];
  String _currentSearchQuery = '';

  Future<void> _onChatRefreshed(ChatRefreshed event, Emitter<ChatState> emit) async {
    // The real-time stream handles data; this event is used to
    // re-emit with current search filter if needed.
    if (_latestChats.isNotEmpty) {
      emit(ChatLoaded(
        chats: _latestChats,
        filteredChats: _filterChats(_latestChats, _currentSearchQuery),
        selectedChatIds: const {},
        searchQuery: _currentSearchQuery,
        isSelecting: false,
      ));
    }
  }

  Future<void> _onChatSelected(ChatSelected event, Emitter<ChatState> emit) async {
    // UI navigation concern — no Firebase write needed here.
  }

  Future<void> _onChatCreated(ChatCreated event, Emitter<ChatState> emit) async {
    try {
      final chatData = <String, dynamic>{
        'participantIds': event.participantIds,
        'isGroup': event.isGroup,
      };
      if (event.groupName != null) {
        chatData['groupName'] = event.groupName;
      }
      await _dbService.createChat(chatData);
    } catch (e) {
      emit(ChatError('Failed to create chat: $e'));
    }
  }

  Future<void> _onChatDeleted(ChatDeleted event, Emitter<ChatState> emit) async {
    try {
      await _dbService.deleteChat(event.chatId);
    } catch (e) {
      emit(ChatError('Failed to delete chat: $e'));
    }
  }

  Future<void> _onChatArchived(ChatArchived event, Emitter<ChatState> emit) async {
    try {
      await _dbService.updateChat(event.chatId, {
        'isArchived': event.isArchived,
      });
    } catch (e) {
      emit(ChatError('Failed to archive chat: $e'));
    }
  }

  Future<void> _onChatPinned(ChatPinned event, Emitter<ChatState> emit) async {
    try {
      await _dbService.updateChat(event.chatId, {
        'isPinned': event.isPinned,
      });
    } catch (e) {
      emit(ChatError('Failed to pin chat: $e'));
    }
  }

  Future<void> _onChatMuted(ChatMuted event, Emitter<ChatState> emit) async {
    try {
      await _dbService.updateChat(event.chatId, {
        'isMuted': event.isMuted,
      });
    } catch (e) {
      emit(ChatError('Failed to mute chat: $e'));
    }
  }

  void _onSearchQueryChanged(ChatSearchQueryChanged event, Emitter<ChatState> emit) {
    _currentSearchQuery = event.query;
    final currentState = state;
    if (currentState is ChatLoaded) {
      final filtered = _filterChats(currentState.chats, event.query);
      emit(currentState.copyWith(searchQuery: event.query, filteredChats: filtered));
    }
  }

  void _onSelectionModeToggled(ChatSelectionModeToggled event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(
        isSelecting: event.isSelecting,
        selectedChatIds: event.isSelecting ? currentState.selectedChatIds : const {},
      ));
    }
  }

  void _onSelectionToggled(ChatSelectionToggled event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded && currentState.isSelecting) {
      final updated = Set<String>.from(currentState.selectedChatIds);
      if (updated.contains(event.chatId)) {
        updated.remove(event.chatId);
      } else {
        updated.add(event.chatId);
      }
      emit(currentState.copyWith(selectedChatIds: updated));
    }
  }

  List<Chat> _filterChats(List<Chat> chats, String query) {
    if (query.trim().isEmpty) return chats;
    final lowerQuery = query.toLowerCase();
    return chats.where((chat) {
      if (chat.isGroup && chat.groupName?.toLowerCase().contains(lowerQuery) == true) return true;
      if (chat.participantNames.any((name) => name.toLowerCase().contains(lowerQuery))) return true;
      if (chat.lastMessageText?.toLowerCase().contains(lowerQuery) == true) return true;
      return false;
    }).toList();
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}
