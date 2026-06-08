import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load the initial list of chats.
class ChatStarted extends ChatEvent {
  const ChatStarted();
}

/// Pull-to-refresh: reload the chat list.
class ChatRefreshed extends ChatEvent {
  const ChatRefreshed();
}

/// User selected a chat to open.
class ChatSelected extends ChatEvent {
  final String chatId;

  const ChatSelected({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

/// Create a new chat (1-on-1 or group).
class ChatCreated extends ChatEvent {
  final List<String> participantIds;
  final bool isGroup;
  final String? groupName;

  const ChatCreated({
    required this.participantIds,
    required this.isGroup,
    this.groupName,
  });

  @override
  List<Object?> get props => [participantIds, isGroup, groupName];
}

/// Delete a chat for the current user.
class ChatDeleted extends ChatEvent {
  final String chatId;

  const ChatDeleted({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

/// Archive or unarchive a chat.
class ChatArchived extends ChatEvent {
  final String chatId;
  final bool isArchived;

  const ChatArchived({
    required this.chatId,
    required this.isArchived,
  });

  @override
  List<Object?> get props => [chatId, isArchived];
}

/// Pin or unpin a chat.
class ChatPinned extends ChatEvent {
  final String chatId;
  final bool isPinned;

  const ChatPinned({
    required this.chatId,
    required this.isPinned,
  });

  @override
  List<Object?> get props => [chatId, isPinned];
}

/// Mute or unmute a chat.
class ChatMuted extends ChatEvent {
  final String chatId;
  final bool isMuted;

  const ChatMuted({
    required this.chatId,
    required this.isMuted,
  });

  @override
  List<Object?> get props => [chatId, isMuted];
}

/// Search query changed — filters the displayed chat list.
class ChatSearchQueryChanged extends ChatEvent {
  final String query;

  const ChatSearchQueryChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Toggle multi-selection mode (for bulk actions).
class ChatSelectionModeToggled extends ChatEvent {
  final bool isSelecting;

  const ChatSelectionModeToggled({required this.isSelecting});

  @override
  List<Object?> get props => [isSelecting];
}

/// Toggle a single chat's selection in selection mode.
class ChatSelectionToggled extends ChatEvent {
  final String chatId;

  const ChatSelectionToggled({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}
