import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/applications/providers/application_provider.dart';
import 'package:apex_hires/features/chat/providers/chat_provider.dart';
import 'package:apex_hires/features/chat/screens/chat_detail_screen.dart';
import 'package:apex_hires/features/recruiter/screens/candidate_detail_screen.dart';
import 'package:apex_hires/features/recruiter/screens/edit_job_screen.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/constants/app_constants.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class JobCandidatesScreen extends StatefulWidget {
  final JobModel job;

  const JobCandidatesScreen({super.key, required this.job});

  @override
  State<JobCandidatesScreen> createState() => _JobCandidatesScreenState();
}

class _JobCandidatesScreenState extends State<JobCandidatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentFilter = 'all';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.job.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Candidate Pipeline',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Job',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditJobScreen(job: widget.job),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter tabs
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
                  _currentFilter = index == 0
                      ? 'all'
                      : AppConstants.applicationStatuses[index - 1];
                });
              },
            ),
          ),

          // Candidates list
          Expanded(
            child: StreamBuilder<List<ApplicationModel>>(
              stream: context
                  .read<ApplicationProvider>()
                  .getApplicationsByJob(widget.job.jobId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const JobListShimmer(itemCount: 5);
                }

                var applications = snapshot.data ?? [];

                if (_currentFilter != 'all') {
                  applications = applications
                      .where((a) => a.status == _currentFilter)
                      .toList();
                }

                if (applications.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: _currentFilter == 'all'
                        ? 'No applicants yet'
                        : 'No ${AppColors.getStatusLabel(_currentFilter)} candidates',
                    subtitle: _currentFilter == 'all'
                        ? 'Share your job listing to attract candidates'
                        : 'Move candidates to this status from the pipeline',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    return _CandidateCard(
                      application: app,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CandidateDetailScreen(
                              application: app,
                              job: widget.job,
                            ),
                          ),
                        );
                      },
                      onStatusChange: (newStatus) async {
                        await context
                            .read<ApplicationProvider>()
                            .updateStatus(app.applicationId, newStatus);
                      },
                      onMessageTap: () async {
                        final chatId =
                            await context.read<ChatProvider>().getOrCreateChat(
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
                                otherUserId: app.seekerId,
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

class _CandidateCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;
  final Function(String) onStatusChange;
  final VoidCallback onMessageTap;

  const _CandidateCard({
    required this.application,
    required this.onTap,
    required this.onStatusChange,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  url: application.seekerAvatar,
                  radius: 22,
                  initials: application.seekerName.isNotEmpty
                      ? application.seekerName.substring(0, 1).toUpperCase()
                      : 'S',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.seekerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (application.seekerHeadline.isNotEmpty)
                        Text(
                          application.seekerHeadline,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusBadge(status: application.status, small: true),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                // Status change dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: application.status,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getStatusColor(application.status),
                        ),
                        items: AppConstants.applicationStatuses.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.getStatusColor(s),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(AppColors.getStatusLabel(s)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) onStatusChange(value);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Message button
                GestureDetector(
                  onTap: onMessageTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // View resume
                if (application.resumeUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(application.resumeUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open resume')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: AppColors.secondaryText,
                      ),
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
