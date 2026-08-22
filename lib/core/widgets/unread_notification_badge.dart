import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apex_hires/core/theme/app_theme.dart';

/// StreamBuilder that shows unread notification count on the bell icon.
/// Counts application status updates + unread chat messages.
class UnreadNotificationBadge extends StatelessWidget {
  final String userId;
  final bool isSeeker;
  final Widget child;

  const UnreadNotificationBadge({
    super.key,
    required this.userId,
    required this.isSeeker,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return child;

    // Listen to applications for status updates
    final appQuery = isSeeker
        ? FirebaseFirestore.instance
            .collection('applications')
            .where('seeker_id', isEqualTo: userId)
            .where('is_read', isEqualTo: false)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('applications')
            .where('recruiter_id', isEqualTo: userId)
            .where('is_read', isEqualTo: false)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: appQuery,
      builder: (context, appSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: userId)
              .snapshots(),
          builder: (context, chatSnapshot) {
            int count = 0;

            // Count unread application notifications
            if (appSnapshot.hasData) {
              for (final doc in appSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'applied';
                
                if (isSeeker) {
                  // Seekers: Only count updates (status changed from 'applied')
                  if (status != 'applied') {
                    count++;
                  }
                } else {
                  // Recruiters: Count everything unread (new applications)
                  count++;
                }
              }
            }

            // Count unread chat messages
            if (chatSnapshot.hasData) {
              for (final doc in chatSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final unreadCount =
                    Map<String, dynamic>.from(data['unread_count'] ?? {});
                count += (unreadCount[userId] ?? 0) as int;
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                if (count > 0)
                  Positioned(
                    right: -4,
                    top: -4,
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
                        count > 99 ? '99+' : '$count',
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
      },
    );
  }
}
