import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apex_hires/core/theme/app_theme.dart';

/// StreamBuilder that shows unread message count on the Messages tab.
/// Listens to the chats collection for the current user's unread counts.
class UnreadMessageBadge extends StatelessWidget {
  final String userId;
  final Widget child;

  const UnreadMessageBadge({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return child;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        int totalUnread = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadCount =
                Map<String, dynamic>.from(data['unread_count'] ?? {});
            totalUnread += (unreadCount[userId] ?? 0) as int;
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (totalUnread > 0)
              Positioned(
                right: -6,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    totalUnread > 99 ? '99+' : '$totalUnread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
