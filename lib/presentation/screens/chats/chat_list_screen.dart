import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/utils/date_formatter.dart';
import 'package:zaxo/domain/entities/chat.dart';
import 'package:zaxo/domain/entities/message.dart';
import 'package:zaxo/presentation/blocs/chat/chat_bloc.dart';
import 'package:zaxo/presentation/blocs/chat/chat_event.dart';
import 'package:zaxo/presentation/blocs/chat/chat_state.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Trigger chat loading when this screen is first built
    context.read<ChatBloc>().add(const ChatStarted());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  context.read<ChatBloc>().add(ChatSearchQueryChanged(query: query));
                },
              )
            : const Text(
                'Zaxo',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColors.textSecondary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  context.read<ChatBloc>().add(const ChatSearchQueryChanged(query: ''));
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading || state is ChatInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is ChatError) {
            return _buildErrorState(state.message);
          }

          if (state is ChatLoaded) {
            final chats = state.filteredChats;
            if (chats.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: chats.length,
              separatorBuilder: (_, __) => Divider(
                color: AppColors.outline.withValues(alpha: 0.2),
                indent: 76,
                endIndent: 16,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _ChatListItem(
                  chat: chat,
                  onTap: () => context.go('/chat/${chat.id}'),
                );
              },
            );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/contacts'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.outline),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation by tapping the chat button',
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.read<ChatBloc>().add(const ChatRefreshed()),
            child: Text('Retry', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({required this.chat, required this.onTap});
  final Chat chat;
  final VoidCallback onTap;

  /// Determine the display name for the chat.
  String get _displayName {
    if (chat.isGroup) return chat.groupName ?? 'Group';
    // For 1-on-1 chats, use the other participant's name
    // (participants list may be empty initially)
    if (chat.participants.isNotEmpty) {
      return chat.participants.first.name;
    }
    return chat.groupName ?? 'Chat';
  }

  /// Whether this is an AI chat.
  bool get _isAI {
    final name = _displayName.toLowerCase();
    return name.contains('zaxo ai') || chat.id.toLowerCase().contains('ai');
  }

  /// Get the online status for non-group chats.
  bool get _isOnline {
    if (chat.isGroup) return false;
    if (chat.participants.isNotEmpty) return chat.participants.first.isOnline;
    return false;
  }

  /// Get the last message status.
  MessageStatus? get _lastMessageStatus => chat.lastMessage?.status;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            ProfileAvatar(
              name: _displayName,
              size: AvatarSize.md,
              isOnline: _isOnline,
              showOnlineIndicator: _isOnline,
              backgroundColor: _isAI ? AppColors.tertiary : null,
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _displayName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isAI) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AI',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                            if (chat.isGroup) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.group, size: 14, color: AppColors.textSecondary),
                            ],
                          ],
                        ),
                      ),
                      // Time
                      if (chat.lastMessageTime != null)
                        Text(
                          DateFormatter.formatChatListTime(chat.lastMessageTime!),
                          style: TextStyle(
                            color: chat.unreadCount > 0 ? AppColors.secondary : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Row(
                    children: [
                      // Message status
                      if (_lastMessageStatus != null && !chat.isGroup)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _StatusIcon(status: _lastMessageStatus!),
                        ),

                      // Last message
                      Expanded(
                        child: Text(
                          chat.lastMessageText ?? '',
                          style: TextStyle(
                            color: chat.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Unread badge
                      if (chat.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.unreadBadge,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 20),
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      // Mute indicator
                      if (chat.isMuted) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.notifications_off, size: 14, color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 14, color: AppColors.textSecondary);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: AppColors.textSecondary);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: AppColors.textSecondary);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: AppColors.secondary);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: AppColors.error);
    }
  }
}
