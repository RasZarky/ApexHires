import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/jobs/providers/job_provider.dart';
import 'package:apex_hires/features/recruiter/screens/post_job_screen.dart';
import 'package:apex_hires/features/recruiter/screens/edit_job_screen.dart';
import 'package:apex_hires/features/recruiter/screens/job_candidates_screen.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Jobs',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostJobScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Job'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<JobModel>>(
        stream: context
            .read<JobProvider>()
            .getJobsByRecruiter(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const JobListShimmer();
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return EmptyState(
              icon: Icons.work_off_outlined,
              title: 'No jobs posted yet',
              subtitle: 'Create your first job listing to start hiring',
              actionLabel: 'Post a Job',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostJobScreen()),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _RecruiterJobCardFull(
                job: job,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobCandidatesScreen(job: job),
                    ),
                  );
                },
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditJobScreen(job: job),
                    ),
                  );
                },
                onStatusToggle: () async {
                  final newStatus =
                      job.status == 'active' ? 'paused' : 'active';
                  await context
                      .read<JobProvider>()
                      .updateJobStatus(job.jobId, newStatus);
                },
                onClose: () async {
                  await context
                      .read<JobProvider>()
                      .updateJobStatus(job.jobId, 'closed');
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RecruiterJobCardFull extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onStatusToggle;
  final VoidCallback onClose;

  const _RecruiterJobCardFull({
    required this.job,
    required this.onTap,
    required this.onEdit,
    required this.onStatusToggle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${job.jobType} • ${job.experienceLevel} • ${job.location}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'toggle') onStatusToggle();
                    if (value == 'close') onClose();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Job'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        job.status == 'active' ? 'Pause' : 'Activate',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'close',
                      child: Text('Close Job',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 320;
                if (isNarrow) {
                  // Stack salary below on very small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusChip(status: job.status),
                          const SizedBox(width: 8),
                          Icon(Icons.people_outline,
                              size: 14, color: AppColors.secondaryText),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${job.applicationsCount} applicants',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.salaryDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    _StatusChip(status: job.status),
                    const SizedBox(width: 8),
                    Icon(Icons.people_outline,
                        size: 16, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${job.applicationsCount} applicants',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      flex: 2,
                      child: Text(
                        job.salaryDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = AppColors.success;
        label = 'Active';
        break;
      case 'paused':
        color = AppColors.warning;
        label = 'Paused';
        break;
      case 'closed':
        color = AppColors.lightText;
        label = 'Closed';
        break;
      default:
        color = AppColors.lightText;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
