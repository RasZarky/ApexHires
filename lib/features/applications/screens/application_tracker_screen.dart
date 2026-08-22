import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/applications/providers/application_provider.dart';
import 'package:apex_hires/features/chat/providers/chat_provider.dart';
import 'package:apex_hires/features/chat/screens/chat_detail_screen.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/constants/app_constants.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class ApplicationTrackerScreen extends StatefulWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  State<ApplicationTrackerScreen> createState() =>
      _ApplicationTrackerScreenState();
}

class _ApplicationTrackerScreenState extends State<ApplicationTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConstants.applicationStatuses.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Applications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Status tabs
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.lightText,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabAlignment: TabAlignment.start,
              tabs: [
                const Tab(text: 'All'),
                ...AppConstants.applicationStatuses.map(
                  (s) => Tab(text: AppColors.getStatusLabel(s)),
                ),
              ],
              onTap: (index) {
                setState(() {
                  _selectedStatus =
                      index == 0 ? 'all' : AppConstants.applicationStatuses[index - 1];
                });
              },
            ),
          ),

          // Applications list
          Expanded(
            child: StreamBuilder<List<ApplicationModel>>(
              stream: context
                  .read<ApplicationProvider>()
                  .getApplicationsBySeeker(user?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const JobListShimmer();
                }

                var applications = snapshot.data ?? [];

                if (_selectedStatus != 'all') {
                  applications = applications
                      .where((a) => a.status == _selectedStatus)
                      .toList();
                }

                if (applications.isEmpty) {
                  return EmptyState(
                    icon: Icons.track_changes_outlined,
                    title: _selectedStatus == 'all'
                        ? 'No applications yet'
                        : 'No ${AppColors.getStatusLabel(_selectedStatus)} applications',
                    subtitle: 'Start applying to jobs to track your progress here',
                    actionLabel: 'Browse Jobs',
                    onAction: () {
                      // Navigate to jobs tab
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    return _ApplicationCard(
                      application: app,
                      onTap: () {
                        if (!app.isRead && app.status != 'applied') {
                          context.read<ApplicationProvider>().markAsRead(app.applicationId);
                        }
                      },
                      onMessageTap: () async {
                        // Also mark as read when starting a chat
                        if (!app.isRead && app.status != 'applied') {
                          context.read<ApplicationProvider>().markAsRead(app.applicationId);
                        }
                        
                        final chatProvider = context.read<ChatProvider>();
                        final chatId = await chatProvider.getOrCreateChat(
                          applicationId: app.applicationId,
                          jobId: app.jobId,
                          seekerId: app.seekerId,
                          recruiterId: app.recruiterId,
                        );
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                chatId: chatId,
                                otherUserId: app.recruiterId,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback? onMessageTap;
  final VoidCallback? onTap;

  const _ApplicationCard({
    required this.application,
    this.onMessageTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // A notification for seeker is an update where status != 'applied'
    final hasUpdate = !application.isRead && application.status != 'applied';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUpdate ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider,
            width: hasUpdate ? 1.5 : 1,
          ),
          boxShadow: hasUpdate 
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              application.jobTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          if (hasUpdate)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied ${DateFormat('MMM d, yyyy').format(application.appliedAt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.lightText,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: application.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                // Status timeline
                Expanded(
                  child: _StatusTimeline(currentStatus: application.status),
                ),
                const SizedBox(width: 12),
                // Message recruiter
                if (application.status != 'rejected')
                  OutlinedButton.icon(
                    onPressed: onMessageTap,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;

  const _StatusTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final stages = ['applied', 'shortlisted', 'interviewing', 'hired'];
    final currentIdx = stages.indexOf(currentStatus);

    return Row(
      children: List.generate(stages.length, (index) {
        final isActive = currentIdx >= index;
        final isCurrent = stages[index] == currentStatus;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: isCurrent ? 12 : 8,
                height: isCurrent ? 12 : 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.getStatusColor(stages[index])
                      : AppColors.divider,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.getStatusColor(stages[index]),
                          width: 2,
                        )
                      : null,
                ),
              ),
              if (index < stages.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isActive
                        ? AppColors.getStatusColor(stages[index])
                            .withValues(alpha: 0.5)
                        : AppColors.divider,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
