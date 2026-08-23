import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/jobs/providers/job_provider.dart';
import 'package:apex_hires/features/jobs/screens/job_detail_screen.dart';
import 'package:apex_hires/features/auth/screens/notifications_screen.dart';
import 'package:apex_hires/features/jobs/screens/bookmarks_screen.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/constants/app_constants.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:apex_hires/core/widgets/unread_notification_badge.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<JobProvider>(
              builder: (context, jobProvider, _) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView(
                    controller: scrollController,
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
                      Text(
                        'Filter Jobs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),

                      // Location
                      TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'Location',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        onChanged: (v) => jobProvider.setLocationFilter(v),
                      ),
                      const SizedBox(height: 16),

                      // Job Type
                      Text(
                        'Job Type',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: jobProvider.jobTypeFilter.isEmpty,
                            onSelected: (_) => jobProvider.setJobTypeFilter(''),
                            selectedColor: AppColors.primary.withValues(alpha: 0.1),
                            checkmarkColor: AppColors.primary,
                          ),
                          ...AppConstants.jobTypes.map((type) {
                            return FilterChip(
                              label: Text(type),
                              selected: jobProvider.jobTypeFilter == type,
                              onSelected: (_) => jobProvider.setJobTypeFilter(
                                jobProvider.jobTypeFilter == type ? '' : type,
                              ),
                              selectedColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              checkmarkColor: AppColors.primary,
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Experience Level
                      Text(
                        'Experience Level',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: jobProvider.experienceFilter.isEmpty,
                            onSelected: (_) =>
                                jobProvider.setExperienceFilter(''),
                            selectedColor: AppColors.primary.withValues(alpha: 0.1),
                            checkmarkColor: AppColors.primary,
                          ),
                          ...AppConstants.experienceLevels.map((level) {
                            return FilterChip(
                              label: Text(level),
                              selected: jobProvider.experienceFilter == level,
                              onSelected: (_) =>
                                  jobProvider.setExperienceFilter(
                                jobProvider.experienceFilter == level
                                    ? ''
                                    : level,
                              ),
                              selectedColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              checkmarkColor: AppColors.primary,
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                jobProvider.clearFilters();
                                _locationController.clear();
                              },
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ApexHires',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookmarksScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: UnreadNotificationBadge(
              userId: context.watch<AuthProvider>().user?.uid ?? '',
              isSeeker: true,
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    hintText: 'Search jobs, companies...',
                    controller: _searchController,
                    onChanged: (v) {
                      context.read<JobProvider>().setSearchQuery(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active filters indicator
          Consumer<JobProvider>(
            builder: (context, jobProvider, _) {
              final hasFilters = jobProvider.jobTypeFilter.isNotEmpty ||
                  jobProvider.experienceFilter.isNotEmpty ||
                  jobProvider.locationFilter.isNotEmpty;
              if (!hasFilters) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (jobProvider.jobTypeFilter.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(jobProvider.jobTypeFilter),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => jobProvider.setJobTypeFilter(''),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (jobProvider.experienceFilter.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text(jobProvider.experienceFilter),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => jobProvider.setExperienceFilter(''),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        jobProvider.clearFilters();
                        _searchController.clear();
                        _locationController.clear();
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Job list
          Expanded(
            child: Consumer<JobProvider>(
              builder: (context, jobProvider, _) {
                return StreamBuilder<List<JobModel>>(
                  stream: jobProvider.searchJobs(),
                  key: ValueKey(
                    '${jobProvider.searchQuery}_${jobProvider.jobTypeFilter}_${jobProvider.experienceFilter}_${jobProvider.locationFilter}',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const JobListShimmer();
                    }

                    final jobs = snapshot.data ?? [];

                    if (jobs.isEmpty) {
                      return EmptyState(
                        icon: Icons.work_off_outlined,
                        title: 'No jobs found',
                        subtitle:
                            'Try adjusting your search filters or check back later',
                        actionLabel: 'Clear Filters',
                        onAction: () {
                          jobProvider.clearFilters();
                          _searchController.clear();
                          _locationController.clear();
                        },
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return _JobCard(
                          job: job,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailScreen(job: job),
                              ),
                            );
                          },
                        );
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

class _JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

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
                // Company Logo
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
                Text(
                  job.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details row
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _DetailChip(
                  icon: Icons.location_on_outlined,
                  label: job.location,
                ),
                _DetailChip(
                  icon: Icons.access_time,
                  label: job.jobType,
                ),
                _DetailChip(
                  icon: Icons.trending_up,
                  label: job.experienceLevel,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job.salaryDisplay,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${job.applicationsCount} applicants',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
            if (job.skillsRequired.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: job.skillsRequired
                    .take(4)
                    .map((skill) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
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
