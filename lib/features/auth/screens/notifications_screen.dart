import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/chat/screens/chat_detail_screen.dart';
import 'package:apex_hires/features/applications/screens/application_tracker_screen.dart';
import 'package:apex_hires/features/recruiter/screens/candidate_detail_screen.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/services/firestore_service.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final isSeeker = user.role == 'job_seeker';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: isSeeker
            ? FirebaseFirestore.instance
                .collection('applications')
                .where('seeker_id', isEqualTo: user.uid)
                .orderBy('updated_at', descending: true)
                .limit(50)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('applications')
                .where('recruiter_id', isEqualTo: user.uid)
                .orderBy('updated_at', descending: true)
                .limit(50)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const JobListShimmer(itemCount: 5);
          }

          final docs = snapshot.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: user.uid)
                .snapshots(),
            builder: (context, chatSnapshot) {
              final chatDocs = chatSnapshot.data?.docs ?? [];

              // Stream for system notifications from the notifications collection
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('user_id', isEqualTo: user.uid)
                    .orderBy('created_at', descending: true)
                    .limit(30)
                    .snapshots(),
                builder: (context, notifSnapshot) {
                  final notifDocs = notifSnapshot.data?.docs ?? [];

              final notifications = <_NotificationItem>[];

              // Application status notifications
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'applied';
                final updatedAt =
                    (data['updated_at'] as Timestamp?)?.toDate();
                final appliedAt =
                    (data['applied_at'] as Timestamp?)?.toDate();
                final isRead = data['is_read'] ?? false;

                if (status != 'applied' && updatedAt != null) {
                  final isAfterApply =
                      appliedAt != null && updatedAt.isAfter(appliedAt);
                  if (isAfterApply) {
                    notifications.add(_NotificationItem(
                      id: doc.id,
                      type: 'application',
                      title: _getStatusTitle(status, data, isSeeker),
                      subtitle: _getStatusSubtitle(status, data, isSeeker),
                      timestamp: updatedAt,
                      status: status,
                      isRead: isRead,
                      icon: _getStatusIcon(status),
                      color: AppColors.getStatusColor(status),
                      jobId: data['job_id'] ?? '',
                      jobTitle: data['job_title'] ?? '',
                      seekerId: data['seeker_id'] ?? '',
                      recruiterId: data['recruiter_id'] ?? '',
                      chatId: '',
                      data: data,
                    ));
                  }
                }
              }

              // Unread chat notifications
              for (final doc in chatDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final unreadCount =
                    Map<String, dynamic>.from(data['unread_count'] ?? {});
                final myUnread = (unreadCount[user.uid] ?? 0) as int;
                if (myUnread > 0) {
                  final lastMessage = data['last_message'] ?? '';
                  final lastTime =
                      (data['last_message_time'] as Timestamp?)?.toDate();
                  final participants =
                      List<String>.from(data['participants'] ?? []);
                  final otherUserId = participants.firstWhere(
                    (id) => id != user.uid,
                    orElse: () => '',
                  );
                  if (lastTime != null) {
                    notifications.add(_NotificationItem(
                      id: doc.id,
                      type: 'message',
                      title: 'New Message',
                      subtitle: lastMessage.length > 60
                          ? '${lastMessage.substring(0, 60)}...'
                          : lastMessage,
                      timestamp: lastTime,
                      isRead: false,
                      icon: Icons.chat_bubble,
                      color: AppColors.primary,
                      jobId: data['job_id'] ?? '',
                      jobTitle: '',
                      seekerId: '',
                      recruiterId: '',
                      chatId: doc.id,
                      otherUserId: otherUserId,
                      data: data,
                    ));
                  }
                }
              }

              // System notifications from notifications collection
              for (final doc in notifDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final createdAt =
                    (data['created_at'] as Timestamp?)?.toDate();
                if (createdAt == null) continue;

                final type = data['type'] ?? 'info';
                final title = data['title'] ?? '';
                final body = data['body'] ?? '';
                final isRead = data['read'] ?? false;

                notifications.add(_NotificationItem(
                  id: doc.id,
                  type: 'system',
                  title: title,
                  subtitle: body,
                  timestamp: createdAt,
                  isRead: isRead,
                  icon: _getSystemNotificationIcon(type),
                  color: _getSystemNotificationColor(type),
                  data: data,
                ));
              }

              notifications.sort(
                  (a, b) => b.timestamp.compareTo(a.timestamp));

              if (notifications.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'No notifications',
                  subtitle:
                      'Application updates and new messages will appear here',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return _NotificationTile(
                    notification: notifications[index],
                    onTap: () async {
                      final n = notifications[index];

                      if (n.type == 'message') {
                        await _markChatAsRead(n.chatId, user.uid);
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                chatId: n.chatId,
                                otherUserId: n.otherUserId,
                              ),
                            ),
                          );
                        }
                      } else if (n.type == 'system') {
                        await _markSystemNotificationAsRead(n.id);
                        if (context.mounted) {
                          if (isSeeker) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ApplicationTrackerScreen(),
                              ),
                            );
                          }
                        }
                      } else {
                        await _markApplicationAsRead(n.id);
                        if (context.mounted) {
                          if (isSeeker) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ApplicationTrackerScreen(),
                              ),
                            );
                          } else {
                            try {
                              final app = ApplicationModel.fromMap(n.data);
                              final job = await FirestoreService().getJobById(n.jobId);
                              if (job != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CandidateDetailScreen(
                                      application: app,
                                      job: job,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Fallback
                            }
                          }
                        }
                      }
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

  Future<void> _markChatAsRead(String chatId, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'unread_count.$userId': 0,
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _markApplicationAsRead(String applicationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({
        'is_read': true,
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _markSystemNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      // ignore
    }
  }

  IconData _getSystemNotificationIcon(String type) {
    switch (type) {
      case 'new_application':
        return Icons.person_add_outlined;
      case 'recruiter_verified':
        return Icons.verified_outlined;
      case 'recruiter_unverified':
        return Icons.gpp_maybe_outlined;
      case 'user_blocked':
        return Icons.block_outlined;
      case 'job_removed':
        return Icons.delete_outline;
      case 'job_paused':
        return Icons.pause_circle_outline;
      case 'job_reactivated':
        return Icons.play_circle_outline;
      case 'application_status_changed':
        return Icons.track_changes_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getSystemNotificationColor(String type) {
    switch (type) {
      case 'new_application':
        return AppColors.primary;
      case 'recruiter_verified':
        return AppColors.success;
      case 'recruiter_unverified':
        return AppColors.warning;
      case 'user_blocked':
        return AppColors.error;
      case 'job_removed':
        return AppColors.error;
      case 'job_paused':
        return AppColors.warning;
      case 'job_reactivated':
        return AppColors.success;
      case 'application_status_changed':
        return AppColors.shortlisted;
      default:
        return AppColors.lightText;
    }
  }

  String _getStatusTitle(
      String status, Map<String, dynamic> data, bool isSeeker) {
    final jobTitle = data['job_title'] ?? '';
    switch (status) {
      case 'shortlisted':
        return isSeeker
            ? 'Shortlisted for $jobTitle'
            : '${data['seeker_name'] ?? 'Candidate'} shortlisted';
      case 'interviewing':
        return isSeeker
            ? 'Interview: $jobTitle'
            : '${data['seeker_name'] ?? 'Candidate'} — Interview stage';
      case 'hired':
        return isSeeker
            ? 'Offer Extended: $jobTitle 🎉'
            : 'Hired: ${data['seeker_name'] ?? 'Candidate'}';
      case 'rejected':
        return isSeeker
            ? 'Update on $jobTitle'
            : 'Rejected: ${data['seeker_name'] ?? 'Candidate'}';
      default:
        return 'Application Update';
    }
  }

  String _getStatusSubtitle(
      String status, Map<String, dynamic> data, bool isSeeker) {
    switch (status) {
      case 'shortlisted':
        return isSeeker
            ? 'Your application has been shortlisted'
            : 'You shortlisted this candidate';
      case 'interviewing':
        return isSeeker
            ? 'You have been moved to the interview stage'
            : 'This candidate is in the interview stage';
      case 'hired':
        return isSeeker
            ? 'Congratulations! You have received an offer'
            : 'You extended an offer to this candidate';
      case 'rejected':
        return isSeeker
            ? 'This position has been filled by another candidate'
            : 'You rejected this candidate';
      default:
        return 'Status updated';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'shortlisted':
        return Icons.star_outline;
      case 'interviewing':
        return Icons.record_voice_over_outlined;
      case 'hired':
        return Icons.celebration_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.update;
    }
  }
}

class _NotificationItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? status;
  final bool isRead;
  final IconData icon;
  final Color color;
  final String jobId;
  final String jobTitle;
  final String seekerId;
  final String recruiterId;
  final String chatId;
  final String otherUserId;
  final Map<String, dynamic> data;

  _NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.status,
    this.isRead = false,
    required this.icon,
    required this.color,
    this.jobId = '',
    this.jobTitle = '',
    this.seekerId = '',
    this.recruiterId = '',
    this.chatId = '',
    this.otherUserId = '',
    required this.data,
  });
}

class _NotificationTile extends StatelessWidget {
  final _NotificationItem notification;
  final VoidCallback? onTap;

  const _NotificationTile({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: notification.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 22,
                  ),
                ),
                if (!notification.isRead)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      if (notification.status != null)
                        StatusBadge(
                            status: notification.status!, small: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: notification.isRead ? AppColors.secondaryText : AppColors.darkText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.lightText,
                    ),
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

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }
}
