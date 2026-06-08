import 'user_model.dart';
import 'message_model.dart';
import '../../domain/entities/chat.dart' as entity;

/// Data model for Chat with JSON serialization support.
class ChatModel {
  final String id;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatar;
  final String? groupDescription;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatModel({
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
  });

  /// Create a ChatModel from a JSON map.
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      groupName: json['groupName'] as String?,
      groupAvatar: json['groupAvatar'] as String?,
      groupDescription: json['groupDescription'] as String?,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => UserModel.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert this ChatModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupAvatar': groupAvatar,
      'groupDescription': groupDescription,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a ChatModel from a domain Chat entity.
  factory ChatModel.fromEntity(entity.Chat chat) {
    return ChatModel(
      id: chat.id,
      isGroup: chat.isGroup,
      groupName: chat.groupName,
      groupAvatar: chat.groupAvatar,
      groupDescription: chat.groupDescription,
      participants: chat.participants
          .map((p) => UserModel.fromEntity(p))
          .toList(),
      lastMessage: chat.lastMessage != null
          ? MessageModel.fromEntity(chat.lastMessage!)
          : null,
      lastMessageTime: chat.lastMessageTime,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
    );
  }

  /// Convert this ChatModel to a domain Chat entity.
  entity.Chat toEntity() {
    return entity.Chat(
      id: id,
      isGroup: isGroup,
      groupName: groupName,
      groupAvatar: groupAvatar,
      groupDescription: groupDescription,
      participants: participants.map((p) => p.toEntity()).toList(),
      lastMessage: lastMessage?.toEntity(),
      lastMessageTime: lastMessageTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ChatModel copyWith({
    String? id,
    bool? isGroup,
    String? groupName,
    String? groupAvatar,
    String? groupDescription,
    List<UserModel>? participants,
    MessageModel? lastMessage,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
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
    );
  }
}
