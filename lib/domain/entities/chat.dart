import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/user.dart';
import 'package:zaxo/domain/entities/message.dart';

class Chat extends Equatable {
  final String id;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatar;
  final String? groupDescription;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Client-side UI state — not persisted.
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;

  const Chat({
    required this.id,
    this.isGroup = false,
    this.groupName,
    this.groupAvatar,
    this.groupDescription,
    this.participants = const [],
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
  });

  /// Convenience: participant IDs.
  List<String> get participantIds =>
      participants.map((p) => p.id).toList();

  /// Convenience: participant names.
  List<String> get participantNames =>
      participants.map((p) => p.name).toList();

  /// Convenience: last message text preview.
  String? get lastMessageText => lastMessage?.content;

  /// Convenience: group photo URL (alias for groupAvatar).
  String? get groupPhotoUrl => groupAvatar;

  Chat copyWith({
    String? id,
    bool? isGroup,
    String? groupName,
    String? groupAvatar,
    String? groupDescription,
    List<User>? participants,
    Message? lastMessage,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
  }) {
    return Chat(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupAvatar: groupAvatar ?? this.groupAvatar,
      groupDescription: groupDescription ?? this.groupDescription,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [
        id,
        isGroup,
        groupName,
        groupAvatar,
        groupDescription,
        participants,
        lastMessage,
        lastMessageTime,
        createdAt,
        updatedAt,
        unreadCount,
        isPinned,
        isMuted,
        isArchived,
      ];
}
