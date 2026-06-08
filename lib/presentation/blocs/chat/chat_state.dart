import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/chat.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any chat action.
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Chat list is loading.
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Chat list has been loaded successfully.
class ChatLoaded extends ChatState {
  /// All chats for the current user.
  final List<Chat> chats;

  /// Chats filtered by the current search query.
  final List<Chat> filteredChats;

  /// IDs of chats currently selected in selection mode.
  final Set<String> selectedChatIds;

  /// Current search query string.
  final String searchQuery;

  /// Whether selection mode is active.
  final bool isSelecting;

  const ChatLoaded({
    required this.chats,
    required this.filteredChats,
    required this.selectedChatIds,
    required this.searchQuery,
    required this.isSelecting,
  });

  /// Convenience getter for pinned chats from [filteredChats].
  List<Chat> get pinnedChats =>
      filteredChats.where((c) => c.isPinned).toList();

  /// Convenience getter for non-pinned chats from [filteredChats].
  List<Chat> get recentChats =>
      filteredChats.where((c) => !c.isPinned).toList();

  /// Convenience getter for archived chats from [chats].
  List<Chat> get archivedChats =>
      chats.where((c) => c.isArchived).toList();

  ChatLoaded copyWith({
    List<Chat>? chats,
    List<Chat>? filteredChats,
    Set<String>? selectedChatIds,
    String? searchQuery,
    bool? isSelecting,
  }) {
    return ChatLoaded(
      chats: chats ?? this.chats,
      filteredChats: filteredChats ?? this.filteredChats,
      selectedChatIds: selectedChatIds ?? this.selectedChatIds,
      searchQuery: searchQuery ?? this.searchQuery,
      isSelecting: isSelecting ?? this.isSelecting,
    );
  }

  @override
  List<Object?> get props => [
        chats,
        filteredChats,
        selectedChatIds,
        searchQuery,
        isSelecting,
      ];
}

/// An error occurred while loading or modifying chats.
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
