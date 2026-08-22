import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/chat/providers/chat_provider.dart';
import 'package:apex_hires/features/chat/screens/chat_detail_screen.dart';
import 'package:apex_hires/services/firestore_service.dart';
import 'package:apex_hires/models/chat_model.dart';
import 'package:apex_hires/models/user_model.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: context.read<ChatProvider>().getChatsForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const JobListShimmer(itemCount: 5);
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              subtitle: 'Start a conversation after applying to a job or reviewing a candidate',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.getOtherParticipantId(user.uid);

              return FutureBuilder<UserModel?>(
                future: FirestoreService().getUserById(otherUserId),
                builder: (context, userSnapshot) {
                  final otherUser = userSnapshot.data;

                  return FutureBuilder<JobModel?>(
                future: chat.jobId.isNotEmpty
                    ? FirestoreService().getJobById(chat.jobId)
                    : Future.value(null),
                builder: (context, jobSnapshot) {
                  final job = jobSnapshot.data;

                  return _ChatTile(
                    chat: chat,
                    otherUserName: otherUser?.fullName ?? 'Unknown',
                    otherUserAvatar: otherUser?.avatarUrl ?? '',
                    jobTitle: job?.title ?? '',
                    currentUserId: user.uid,
                    onTap: () {
                      final unreadCount = chat.unreadCount[user.uid] ?? 0;
                      if (unreadCount > 0) {
                        context.read<ChatProvider>().markAsRead(
                              chat.chatId,
                              user.uid,
                            );
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatId: chat.chatId,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String otherUserName;
  final String otherUserAvatar;
  final String jobTitle;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.jobTitle = '',
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCount[currentUserId] ?? 0;
    final hasUnread = unread > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: hasUnread
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.03),
                border: const Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              )
            : const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
        child: Row(
          children: [
            Stack(
              children: [
                ProfileAvatar(
                  url: otherUserAvatar,
                  radius: 24,
                  initials: otherUserName.isNotEmpty
                      ? otherUserName.substring(0, 1).toUpperCase()
                      : 'U',
                ),
                // Online indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUserName,
                        style: TextStyle(
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.lightText,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (jobTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      jobTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage.isNotEmpty
                              ? chat.lastMessage
                              : 'Start a conversation...',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? AppColors.darkText
                                : AppColors.lightText,
                            fontWeight:
                                hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return DateFormat('EEE').format(time);
      return DateFormat('MMM d').format(time);
    }
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Now';
  }
}
