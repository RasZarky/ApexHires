import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/chat/providers/chat_provider.dart';
import 'package:apex_hires/services/firestore_service.dart';
import 'package:apex_hires/models/chat_model.dart';
import 'package:apex_hires/models/user_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
    // Mark messages as read
    final currentUserId = context.read<AuthProvider>().user?.uid;
    if (currentUserId != null) {
      context.read<ChatProvider>().markAsRead(widget.chatId, currentUserId);
    }
  }

  Future<void> _loadOtherUser() async {
    final user = await FirestoreService().getUserById(widget.otherUserId);
    if (mounted) setState(() => _otherUser = user);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    context.read<ChatProvider>().sendMessage(
          chatId: widget.chatId,
          senderId: currentUser.uid,
          receiverId: widget.otherUserId,
          text: text,
        );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            ProfileAvatar(
              url: _otherUser?.avatarUrl ?? '',
              radius: 18,
              initials: _otherUser?.fullName.isNotEmpty == true
                  ? _otherUser!.fullName.substring(0, 1).toUpperCase()
                  : 'U',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser?.fullName ?? 'Loading...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_otherUser != null)
                    Text(
                      _otherUser!.role == 'recruiter'
                          ? _otherUser!.recruiterProfile?.companyName ?? ''
                          : _otherUser!.seekerProfile?.headline ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightText,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: context.read<ChatProvider>().getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: AppColors.lightText),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: AppColors.lightText,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            color: AppColors.lightText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    final showDate = index == 0 ||
                        !_isSameDay(
                          messages[index].createdAt,
                          messages[index - 1].createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDate(message.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lightText,
                                ),
                              ),
                            ),
                          ),
                        _MessageBubble(
                          message: message.text,
                          isMe: isMe,
                          time: _formatTime(message.createdAt),
                          isRead: message.isRead,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.divider,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.divider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${time.day}/${time.month}/${time.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  final bool isRead;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.time,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : AppColors.darkText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.lightText,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
