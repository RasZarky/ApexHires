import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/applications/providers/application_provider.dart';
import 'package:apex_hires/features/applications/screens/easy_apply_screen.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _hasApplied = false;
  bool _checkingApplication = true;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkIfApplied();
    _checkIfBookmarked();
  }

  Future<void> _checkIfApplied() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final already = await context
          .read<ApplicationProvider>()
          .hasAlreadyApplied(widget.job.jobId, user.uid);
      if (mounted) {
        setState(() {
          _hasApplied = already;
          _checkingApplication = false;
        });
      }
    }
  }

  Future<void> _checkIfBookmarked() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(widget.job.jobId)
        .get();
    if (mounted) {
      setState(() => _isBookmarked = doc.exists);
    }
  }

  Future<void> _toggleBookmark() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Optimistic update — change UI immediately
    final newBookmarked = !_isBookmarked;
    setState(() => _isBookmarked = newBookmarked);

    // Show snackbar immediately
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newBookmarked ? 'Job bookmarked' : 'Bookmark removed'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Save to Firestore in background
    final bookmarkRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(widget.job.jobId);

    try {
      if (newBookmarked) {
        await bookmarkRef.set({
          'job_id': widget.job.jobId,
          'saved_at': FieldValue.serverTimestamp(),
        });
      } else {
        await bookmarkRef.delete();
      }
    } catch (e) {
      // Revert if Firestore fails
      if (mounted) {
        setState(() => _isBookmarked = !newBookmarked);
      }
    }
  }

  void _shareJob() {
    final job = widget.job;
    final text = 'Check out this job: ${job.title} at ${job.companyName}\n'
        '${job.location} • ${job.jobType} • ${job.experienceLevel}\n'
        '${job.salaryDisplay}\n\n'
        'Find more jobs on ApexHires!';

    Share.share(
      text,
      subject: '${job.title} at ${job.companyName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? AppColors.primary : null,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareJob,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company & Title Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  ProfileAvatar(
                    url: job.companyLogoUrl,
                    radius: 36,
                    initials: job.companyName.substring(0, 1).toUpperCase(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    job.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.companyName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoBadge(icon: Icons.location_on_outlined, text: job.location),
                      _InfoBadge(icon: Icons.access_time, text: job.jobType),
                      _InfoBadge(icon: Icons.trending_up, text: job.experienceLevel),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    job.salaryDisplay,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Info
            Row(
              children: [
                _QuickInfoCard(
                  icon: Icons.people_outline,
                  label: '${job.applicationsCount}',
                  sublabel: 'Applicants',
                ),
                const SizedBox(width: 12),
                _QuickInfoCard(
                  icon: Icons.schedule,
                  label: job.timeAgo,
                  sublabel: 'Posted',
                ),
                const SizedBox(width: 12),
                _QuickInfoCard(
                  icon: Icons.circle,
                  label: job.status,
                  sublabel: 'Status',
                  statusColor: job.status == 'active'
                      ? AppColors.success
                      : AppColors.lightText,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            _SectionCard(
              title: 'Job Description',
              child: Text(
                job.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Skills Required
            if (job.skillsRequired.isNotEmpty) ...[
              _SectionCard(
                title: 'Required Skills',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.skillsRequired
                      .map((skill) => SkillChip(skill: skill))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Screening Questions
            if (job.screeningQuestions.isNotEmpty) ...[
              _SectionCard(
                title: 'Screening Questions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.screeningQuestions.length} questions to answer when applying',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ...job.screeningQuestions.map((q) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.help_outline,
                                  size: 16, color: AppColors.lightText),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.questionText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              if (q.isRequired)
                                const Text(
                                  '*',
                                  style: TextStyle(color: AppColors.error),
                                ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      // Apply button
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: SafeArea(
          child: _checkingApplication
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _hasApplied
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EasyApplyScreen(job: job),
                              ),
                            ).then((_) => _checkIfApplied());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _hasApplied ? 'Already Applied ✓' : 'Easy Apply',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryText),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color? statusColor;

  const _QuickInfoCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: statusColor ?? AppColors.secondaryText),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: statusColor ?? AppColors.darkText,
              ),
            ),
            Text(
              sublabel,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
