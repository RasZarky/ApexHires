import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
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
              'Applications',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'View all applications across the platform',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _statusFilter == 'all',
                    onSelected: (_) =>
                        setState(() => _statusFilter = 'all'),
                    selectedColor:
                        AppColors.primary.withAlpha(20),
                    checkmarkColor: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  ...[
                    'applied',
                    'shortlisted',
                    'interviewing',
                    'hired',
                    'rejected'
                  ].map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(AppColors.getStatusLabel(s)),
                        selected: _statusFilter == s,
                        onSelected: (_) =>
                            setState(() => _statusFilter = s),
                        selectedColor: AppColors.getStatusColor(s)
                            .withAlpha(20),
                        checkmarkColor: AppColors.getStatusColor(s),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Applications list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .orderBy('applied_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var apps = snapshot.data?.docs
                          .map((doc) => ApplicationModel.fromMap(
                              doc.data() as Map<String, dynamic>))
                          .toList() ??
                      [];

                  // All apps for summary counts
                  final allApps = apps;

                  if (_statusFilter != 'all') {
                    apps = apps
                        .where((a) => a.status == _statusFilter)
                        .toList();
                  }

                  if (apps.isEmpty) {
                    return const EmptyState(
                      icon: Icons.track_changes_outlined,
                      title: 'No applications found',
                      subtitle: 'No applications match your current filter',
                    );
                  }

                  // Status counts
                  final statusCounts = <String, int>{};
                  for (final app in allApps) {
                    statusCounts[app.status] =
                        (statusCounts[app.status] ?? 0) + 1;
                  }

                  if (isMobile) {
                    return Column(
                      children: [
                        // Summary row
                        _buildStatusSummary(statusCounts, isMobile),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: apps.length,
                            itemBuilder: (context, index) {
                              return _MobileApplicationCard(
                                  application: apps[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      // Summary row
                      _buildStatusSummary(statusCounts, isMobile),
                      const SizedBox(height: 16),
                      // Table
                      Expanded(
                        child: _buildDesktopTable(apps),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary(
      Map<String, int> statusCounts, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: isMobile
          ? Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                'applied',
                'shortlisted',
                'interviewing',
                'hired',
                'rejected'
              ].map((s) {
                return _StatusCount(
                  label: AppColors.getStatusLabel(s),
                  count: statusCounts[s] ?? 0,
                  color: AppColors.getStatusColor(s),
                );
              }).toList(),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                'applied',
                'shortlisted',
                'interviewing',
                'hired',
                'rejected'
              ].map((s) {
                return _StatusCount(
                  label: AppColors.getStatusLabel(s),
                  count: statusCounts[s] ?? 0,
                  color: AppColors.getStatusColor(s),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildDesktopTable(List<ApplicationModel> apps) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
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
                    flex: 2,
                    child: Text('Candidate',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 2,
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
                    child: Text('Applied',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return _DesktopApplicationRow(application: app);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status count item ───
class _StatusCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.lightText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Mobile application card ───
class _MobileApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _MobileApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  application.jobTitle,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (application.seekerHeadline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    application.seekerHeadline,
                    style: const TextStyle(
                      color: AppColors.lightText,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: application.status, small: true),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d').format(application.appliedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.lightText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Desktop application row ───
class _DesktopApplicationRow extends StatelessWidget {
  final ApplicationModel application;

  const _DesktopApplicationRow({required this.application});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                ProfileAvatar(
                  url: application.seekerAvatar,
                  radius: 16,
                  initials: application.seekerName.isNotEmpty
                      ? application.seekerName
                          .substring(0, 1)
                          .toUpperCase()
                      : 'S',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.seekerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        application.seekerHeadline,
                        style: const TextStyle(
                          color: AppColors.lightText,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              application.jobTitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: application.status, small: true),
            ),
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('MMM d').format(application.appliedAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
