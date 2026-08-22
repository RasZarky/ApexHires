import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/jobs/screens/job_detail_screen.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Saved Jobs',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .orderBy('saved_at', descending: true)
            .snapshots(),
        builder: (context, bookmarkSnapshot) {
          if (bookmarkSnapshot.connectionState == ConnectionState.waiting) {
            return const JobListShimmer(itemCount: 5);
          }

          final bookmarks = bookmarkSnapshot.data?.docs ?? [];

          if (bookmarks.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved jobs',
              subtitle: 'Tap the bookmark icon on any job to save it here',
            );
          }

          // Get all bookmarked job IDs
          final jobIds =
              bookmarks.map((b) => b['job_id'] as String).toList();

          // Fetch actual job details
          return FutureBuilder<List<DocumentSnapshot>>(
            future: _fetchJobs(jobIds),
            builder: (context, jobSnapshot) {
              if (jobSnapshot.connectionState == ConnectionState.waiting) {
                return const JobListShimmer(itemCount: 5);
              }

              final jobDocs = jobSnapshot.data ?? [];
              final jobs = jobDocs
                  .where((doc) => doc.exists)
                  .map((doc) =>
                      JobModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              if (jobs.isEmpty) {
                return const EmptyState(
                  icon: Icons.bookmark_border,
                  title: 'No saved jobs',
                  subtitle: 'Some saved jobs may have been removed',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return _BookmarkedJobCard(
                    job: job,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(job: job),
                        ),
                      );
                    },
                    onRemove: () => _removeBookmark(context, user.uid, job.jobId),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _fetchJobs(List<String> jobIds) async {
    if (jobIds.isEmpty) return [];

    // Firestore `in` query supports max 30 items
    final batches = <Future<List<DocumentSnapshot>>>[];
    for (var i = 0; i < jobIds.length; i += 30) {
      final batch = jobIds.sublist(
        i,
        i + 30 > jobIds.length ? jobIds.length : i + 30,
      );
      batches.add(FirebaseFirestore.instance
          .collection('jobs')
          .where(FieldPath.documentId, whereIn: batch)
          .get()
          .then((snap) => snap.docs));
    }

    final results = await Future.wait(batches);
    return results.expand((list) => list).toList();
  }

  void _removeBookmark(BuildContext context, String userId, String jobId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(jobId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _BookmarkedJobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _BookmarkedJobCard({
    required this.job,
    required this.onTap,
    required this.onRemove,
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
                ProfileAvatar(
                  url: job.companyLogoUrl,
                  radius: 24,
                  initials: job.companyName.isNotEmpty
                      ? job.companyName.substring(0, 1).toUpperCase()
                      : 'C',
                ),
                const SizedBox(width: 12),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.companyName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bookmark,
                    color: AppColors.primary,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Remove bookmark',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _DetailChip(
                    icon: Icons.location_on_outlined, label: job.location),
                _DetailChip(icon: Icons.access_time, label: job.jobType),
                _DetailChip(
                    icon: Icons.trending_up, label: job.experienceLevel),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.salaryDisplay,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.lightText),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
