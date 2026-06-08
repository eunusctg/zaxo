import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/core/utils/date_formatter.dart';
import 'package:zaxo/domain/entities/message.dart';
import 'package:zaxo/presentation/blocs/message/message_bloc.dart';
import 'package:zaxo/presentation/blocs/message/message_event.dart';
import 'package:zaxo/presentation/blocs/message/message_state.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';
import 'package:zaxo/presentation/widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  bool _showLocalTyping = false; // Local typing indicator for AI chats
  String _chatName = 'Chat';
  bool _isOnline = false;
  bool _isAIChat = false;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Determine chat properties from chatId
    _isAIChat = widget.chatId.toLowerCase().contains('ai') ||
        widget.chatId.toLowerCase().contains('zaxo');
    _chatName = _isAIChat ? 'Zaxo AI' : 'Chat';
    _isOnline = _isAIChat; // AI is always "online"

    // Load messages for this chat
    context.read<MessageBloc>().add(MessageLoadRequested(chatId: widget.chatId));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<MessageBloc>().add(MessageSent(
          chatId: widget.chatId,
          content: text,
        ));
    _messageController.clear();
    _scrollToBottom();

    // Show local typing indicator for AI chats — the actual AI response
    // will arrive via the Firebase real-time stream handled by MessageBloc.
    if (_isAIChat) {
      setState(() => _showLocalTyping = true);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _attachOption(Icons.photo_library, 'Photo', AppColors.primary),
                _attachOption(Icons.camera_alt, 'Camera', AppColors.secondary),
                _attachOption(Icons.insert_drive_file, 'Document', AppColors.tertiary),
                _attachOption(Icons.headset, 'Audio', Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _attachOption(Icons.person, 'Contact', Colors.blue),
                _attachOption(Icons.location_on, 'Location', Colors.green),
                _attachOption(Icons.barcode_reader, 'QR Code', Colors.teal),
                _attachOption(Icons.poll, 'Poll', Colors.pink),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _attachOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? 'me';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            ProfileAvatar(
              name: _chatName,
              size: AvatarSize.sm,
              isOnline: _isOnline,
              showOnlineIndicator: _isOnline,
              backgroundColor: _isAIChat ? AppColors.tertiary : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chatName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    _showLocalTyping ? 'typing...' : (_isOnline ? 'Online' : 'Offline'),
                    style: TextStyle(
                      color: _showLocalTyping ? AppColors.secondary : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: AppColors.textSecondary),
            onPressed: () => context.go('/call/video/${widget.chatId}'),
          ),
          IconButton(
            icon: Icon(Icons.call_outlined, color: AppColors.textSecondary),
            onPressed: () => context.go('/call/audio/${widget.chatId}'),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Encryption banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(
                  'Messages are end-to-end encrypted',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: BlocConsumer<MessageBloc, MessageState>(
              listener: (context, state) {
                // When new messages arrive (from Firebase real-time stream),
                // dismiss the local typing indicator and scroll to bottom.
                if (state is MessageLoaded) {
                  if (state.messages.length > _prevMessageCount) {
                    // New message(s) arrived
                    if (_showLocalTyping) {
                      // Check if any new message is from someone else (AI/other user)
                      final newMessages = state.messages.skip(_prevMessageCount);
                      final hasOtherMessage = newMessages.any(
                        (m) => m.senderId != _currentUserId,
                      );
                      if (hasOtherMessage) {
                        setState(() => _showLocalTyping = false);
                      }
                    }
                    _scrollToBottom();
                  }
                  _prevMessageCount = state.messages.length;
                }
              },
              builder: (context, state) {
                if (state is MessageLoading || state is MessageInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is MessageError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                List<Message> messages = [];
                if (state is MessageLoaded) {
                  messages = state.messages;
                } else if (state is MessageSending) {
                  messages = state.messages;
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.outline),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hello! 👋',
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length + (_showLocalTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_showLocalTyping && index == messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const TypingIndicator(visible: true, dotSize: 6),
                        ),
                      );
                    }

                    final message = messages[index];
                    final isMine = message.senderId == _currentUserId;
                    final showTail = index == messages.length - 1 ||
                        messages[index + 1].senderId != message.senderId;

                    return _buildMessageBubble(message, isMine, showTail);
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.outline.withValues(alpha: 0.2), width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Attach
                  IconButton(
                    icon: Icon(Icons.attach_file, color: AppColors.textSecondary),
                    onPressed: _showAttachmentSheet,
                  ),

                  // Text input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _inputFocusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),

                  // Emoji or Mic/Send
                  if (_messageController.text.isEmpty)
                    IconButton(
                      icon: Icon(Icons.mic, color: AppColors.textSecondary),
                      onPressed: () {},
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 18),
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMine, bool showTail) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: EdgeInsets.only(
          left: isMine ? 48.0 : 12.0,
          right: isMine ? 12.0 : 48.0,
          top: 2.0,
          bottom: 2.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isMine ? AppColors.chatBubbleSent : null,
          color: isMine ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : (showTail ? 4 : 16)),
            bottomRight: Radius.circular(isMine ? (showTail ? 4 : 16) : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.formatMessageTime(message.createdAt),
                  style: TextStyle(
                    color: isMine ? Colors.white60 : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 14, color: Colors.white38);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: Colors.white60);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: AppColors.secondary);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: AppColors.error);
    }
  }
}
