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

  // --- Mobile: card list ---
  Widget _buildMobileJobList(List<JobModel> jobs) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return _MobileJobCard(job: jobs[index]);
      },
    );
  }

  // --- Desktop: table ---
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
                    child: Text('Posted On',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 1,
                    child: Text('Applied Users',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 1,
                    child: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 1,
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

// --- Mobile job card ---
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
                      '${job.companyName} \u2022 ${job.location}',
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
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleAction(context, value, adminProvider),
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.secondaryText),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18, color: AppColors.secondaryText),
                        SizedBox(width: 10),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          job.status == 'active'
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Text(job.status == 'active' ? 'Pause' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Remove', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Posted ${DateFormat('MMM d, yyyy').format(job.createdAt)}',
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
                  '${job.applicationsCount} applicants',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(
      BuildContext context, String value, AdminProvider adminProvider) {
    switch (value) {
      case 'view':
        _showJobDetails(context, job);
        break;
      case 'toggle':
        adminProvider.pauseJob(job.jobId);
        break;
      case 'remove':
        _confirmRemove(context, adminProvider);
        break;
    }
  }

  void _showJobDetails(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _JobDetailsSheet(
          job: job,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, AdminProvider adminProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            child:
                const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await adminProvider.removeJob(job.jobId);
    }
  }
}

// --- Desktop job row ---
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
          // Job column
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
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${job.companyName} \u2022 ${job.location}',
                  style: const TextStyle(
                    color: AppColors.lightText,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Posted On column
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('MMM d, yyyy').format(job.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          // Applied Users column
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${job.applicationsCount}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Status column
          Expanded(
            flex: 1,
            child: StatusBadge(status: job.status, small: true),
          ),
          // Actions column (3-dot menu)
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _showJobDetails(context, job);
                    break;
                  case 'toggle':
                    adminProvider.pauseJob(job.jobId);
                    break;
                  case 'remove':
                    _confirmRemove(context, adminProvider);
                    break;
                }
              },
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.more_vert, size: 20, color: AppColors.secondaryText),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: AppColors.secondaryText),
                      SizedBox(width: 10),
                      Text('View Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        job.status == 'active'
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Text(job.status == 'active' ? 'Pause' : 'Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Remove', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetails(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _JobDetailsSheet(
          job: job,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, AdminProvider adminProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            child:
                const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await adminProvider.removeJob(job.jobId);
    }
  }
}

// --- Job details bottom sheet ---
class _JobDetailsSheet extends StatelessWidget {
  final JobModel job;
  final ScrollController scrollController;

  const _JobDetailsSheet({
    required this.job,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Job title and company
          Text(
            job.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            job.companyName,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Status and applications count row
          Row(
            children: [
              StatusBadge(status: job.status),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${job.applicationsCount} applicants',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: job.location,
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Job Type',
                  value: job.jobType,
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.trending_up_outlined,
                  label: 'Experience',
                  value: job.experienceLevel,
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.attach_money_outlined,
                  label: 'Salary',
                  value: job.salaryDisplay,
                  valueColor: AppColors.primary,
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Posted',
                  value: DateFormat('MMMM d, yyyy').format(job.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          if (job.description.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Skills
          if (job.skillsRequired.isNotEmpty) ...[
            const Text(
              'Required Skills',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.skillsRequired
                  .map((skill) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Screening questions
          if (job.screeningQuestions.isNotEmpty) ...[
            const Text(
              'Screening Questions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            ...job.screeningQuestions.map((q) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        q.isRequired
                            ? Icons.check_circle_outline
                            : Icons.circle_outlined,
                        size: 16,
                        color: q.isRequired
                            ? AppColors.primary
                            : AppColors.lightText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q.questionText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.lightText),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.lightText,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.darkText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
