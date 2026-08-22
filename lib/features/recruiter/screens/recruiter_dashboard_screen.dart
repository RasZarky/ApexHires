import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/jobs/providers/job_provider.dart';
import 'package:apex_hires/features/applications/providers/application_provider.dart';
import 'package:apex_hires/features/auth/screens/notifications_screen.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:apex_hires/core/widgets/unread_notification_badge.dart';
import 'package:apex_hires/features/recruiter/screens/post_job_screen.dart';
import 'package:apex_hires/features/recruiter/screens/job_candidates_screen.dart';
import 'package:apex_hires/features/recruiter/screens/my_jobs_screen.dart';

class RecruiterDashboardScreen extends StatefulWidget {
  const RecruiterDashboardScreen({super.key});

  @override
  State<RecruiterDashboardScreen> createState() => _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState extends State<RecruiterDashboardScreen> {
  bool _recentApplicationsExpanded = true;
  bool _yourJobsExpanded = true;
  Stream<List<ApplicationModel>>? _applicationsStream;
  Stream<List<JobModel>>? _jobsStream;
  String? _lastUid;

  void _updateStreams(String uid) {
    if (uid == _lastUid) return;
    _lastUid = uid;
    if (uid.isNotEmpty) {
      _applicationsStream = context.read<ApplicationProvider>().getApplicationsByRecruiter(uid);
      _jobsStream = context.read<JobProvider>().getJobsByRecruiter(uid);
    } else {
      _applicationsStream = null;
      _jobsStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final String uid = user?.uid ?? '';
    _updateStreams(uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Hello, ${user?.fullName ?? ''} 👋',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: UnreadNotificationBadge(
              userId: user?.uid ?? '',
              isSeeker: false,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            StreamBuilder<List<JobModel>>(
              stream: _jobsStream,
              builder: (context, jobSnapshot) {
                final jobs = jobSnapshot.data ?? [];
                final activeJobs =
                    jobs.where((j) => j.status == 'active').length;

                return StreamBuilder<List<ApplicationModel>>(
                  stream: _applicationsStream,
                  builder: (context, appSnapshot) {
                    final applications = appSnapshot.data ?? [];
                    final newApps = applications
                        .where((a) => a.status == 'applied')
                        .length;
                    final shortlisted = applications
                        .where((a) => a.status == 'shortlisted')
                        .length;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          _StatCard(
                            title: 'Active Jobs',
                            value: '$activeJobs',
                            icon: Icons.work_outline,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            title: 'New Applicants',
                            value: '$newApps',
                            icon: Icons.person_add_outlined,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            title: 'Shortlisted',
                            value: '$shortlisted',
                            icon: Icons.star_outline,
                            color: AppColors.shortlisted,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 8),

            // Post a Job Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PostJobScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Post a New Job',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recent Applications
            GestureDetector(
              onTap: () => setState(() => _recentApplicationsExpanded = !_recentApplicationsExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  const Expanded(
                    child: SectionHeader(
                      title: 'Recent Applications',
                      // Removed non-existent RecruiterApplicationsScreen navigation
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      _recentApplicationsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<ApplicationModel>>(
              stream: _applicationsStream,
              builder: (context, snapshot) {
                if (!_recentApplicationsExpanded) return const SizedBox.shrink();

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const JobListShimmer(itemCount: 3);
                }

                final applications = (snapshot.data ?? []).take(5).toList();

                if (applications.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No applications yet. Post a job to get started!',
                        style: TextStyle(
                            color: AppColors.lightText, fontSize: 14),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: applications.map((app) {
                      return _RecentApplicantCard(application: app);
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Your Jobs
            GestureDetector(
              onTap: () => setState(() => _yourJobsExpanded = !_yourJobsExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'Your Jobs',
                      actionLabel: 'See All',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyJobsScreen()),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      _yourJobsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<JobModel>>(
              stream: _jobsStream,
              builder: (context, snapshot) {
                if (!_yourJobsExpanded) return const SizedBox.shrink();

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const JobListShimmer(itemCount: 3);
                }

                final jobs = (snapshot.data ?? []).take(5).toList();

                if (jobs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No jobs posted yet',
                        style: TextStyle(
                            color: AppColors.lightText, fontSize: 14),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: jobs.map((job) {
                      return _RecruiterJobCard(
                        job: job,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JobCandidatesScreen(job: job),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentApplicantCard extends StatelessWidget {
  final ApplicationModel application;

  const _RecentApplicantCard({required this.application});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            url: application.seekerAvatar,
            radius: 20,
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
                    fontSize: 14,
                  ),
                ),
                Text(
                  application.jobTitle,
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
    );
  }
}

class _RecruiterJobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _RecruiterJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.work_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${job.jobType} • ${job.applicationsCount} applicants',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: job.status == 'active'
                    ? AppColors.success
                    : AppColors.lightText,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
