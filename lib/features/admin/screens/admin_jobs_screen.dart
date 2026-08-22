import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/admin/providers/admin_provider.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final padding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Moderation',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Review, pause, or remove job listings',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Filters
            if (isMobile)
              Column(
                children: [
                  CustomSearchBar(
                    hintText: 'Search by title or company...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'paused', child: Text('Paused')),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (v) =>
                        setState(() => _statusFilter = v ?? 'all'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomSearchBar(
                      hintText: 'Search jobs by title or company...',
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Status')),
                        DropdownMenuItem(
                            value: 'active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'paused', child: Text('Paused')),
                        DropdownMenuItem(
                            value: 'closed', child: Text('Closed')),
                      ],
                      onChanged: (v) =>
                          setState(() => _statusFilter = v ?? 'all'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Jobs list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('jobs').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var jobs = snapshot.data?.docs
                          .map((doc) => JobModel.fromMap(
                              doc.data() as Map<String, dynamic>))
                          .toList() ??
                      [];

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    jobs = jobs
                        .where((j) =>
                            j.title.toLowerCase().contains(q) ||
                            j.companyName.toLowerCase().contains(q))
                        .toList();
                  }

                  if (_statusFilter != 'all') {
                    jobs =
                        jobs.where((j) => j.status == _statusFilter).toList();
                  }

                  if (jobs.isEmpty) {
                    return const EmptyState(
                      icon: Icons.work_off_outlined,
                      title: 'No jobs found',
                      subtitle: 'Try adjusting your filters',
                    );
                  }

                  if (isMobile) {
                    return _buildMobileJobList(jobs);
                  }
                  return _buildDesktopJobTable(jobs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mobile: card list ───
  Widget _buildMobileJobList(List<JobModel> jobs) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return _MobileJobCard(job: jobs[index]);
      },
    );
  }

  // ─── Desktop: table ───
  Widget _buildDesktopJobTable(List<JobModel> jobs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Job',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 1,
                    child: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 1,
                    child: Text('Posted',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 1,
                    child: Text('Apps',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 2,
                    child: Text('Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                return _DesktopJobRow(job: jobs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile job card ───
class _MobileJobCard extends StatelessWidget {
  final JobModel job;

  const _MobileJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.read<AdminProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.companyName} • ${job.location}',
                      style: const TextStyle(
                        color: AppColors.lightText,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: job.status, small: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Posted ${DateFormat('MMM d').format(job.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightText,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${job.applicationsCount} apps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  await adminProvider.pauseJob(job.jobId);
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: Text(job.status == 'active' ? 'Pause' : 'Activate'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      title: const Text('Remove Job'),
                      content: Text(
                          'Are you sure you want to permanently remove "${job.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remove',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await adminProvider.removeJob(job.jobId);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: AppColors.error),
                  textStyle:
                      const TextStyle(fontSize: 11, color: AppColors.error),
                ),
                child:
                    const Text('Remove', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Desktop job row ───
class _DesktopJobRow extends StatelessWidget {
  final JobModel job;

  const _DesktopJobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.read<AdminProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
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
                  '${job.companyName} • ${job.location}',
                  style: const TextStyle(
                    color: AppColors.lightText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: StatusBadge(status: job.status, small: true),
          ),
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('MMM d').format(job.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${job.applicationsCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    await adminProvider.pauseJob(job.jobId);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: Text(
                    job.status == 'active' ? 'Pause' : 'Activate',
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        title: const Text('Remove Job'),
                        content: Text(
                            'Are you sure you want to permanently remove "${job.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Remove',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await adminProvider.removeJob(job.jobId);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: AppColors.error),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Remove',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
