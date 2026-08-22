import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:apex_hires/features/admin/providers/admin_provider.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final padding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Platform overview and real-time metrics',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // ─── Metrics: row on large screens, 2×2 grid on smaller ───
            _buildMetricsGrid(context, isMobile, screenWidth),
            const SizedBox(height: 24),

            // ─── Charts Row ───
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _buildChartsSection(context, isMobile, screenWidth),

            const SizedBox(height: 24),

            // ─── Recent Activity ───
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _buildActivitySection(context, isMobile),
          ],
        ),
      ),
        ),
      ),
    );
  }

  // ─── Metrics: row on large screens, 2×2 grid on smaller ───
  Widget _buildMetricsGrid(BuildContext context, bool isMobile, double screenWidth) {
    final adminProvider = context.read<AdminProvider>();

    final metrics = [
      _MetricData('Users', adminProvider.totalUsers, Icons.people_outline_rounded, AppColors.primary),
      _MetricData('Jobs', adminProvider.totalJobs, Icons.work_outline_rounded, AppColors.accent),
      _MetricData('Applications', adminProvider.totalApplications, Icons.track_changes_rounded, AppColors.shortlisted),
      _MetricData('Chats', adminProvider.totalActiveChats, Icons.chat_bubble_outline_rounded, AppColors.success),
    ];

    // Large screens: all 4 in a row
    if (screenWidth >= 900) {
      return Row(
        children: metrics.map((m) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _MetricCard(
                title: m.title,
                stream: m.stream,
                icon: m.icon,
                color: m.color,
              ),
            ),
          );
        }).toList(),
      );
    }

    // Smaller screens: 2×2 grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 1.6 : 2.0,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return _MetricCard(
          title: m.title,
          stream: m.stream,
          icon: m.icon,
          color: m.color,
        );
      },
    );
  }

  // ─── Charts Section ───
  Widget _buildChartsSection(BuildContext context, bool isMobile, double screenWidth) {
    if (isMobile) {
      return Column(
        children: [
          _ApplicationStatusPieChart(),
          const SizedBox(height: 14),
          _ApplicationTrendBarChart(),
          const SizedBox(height: 14),
          _UserRolePieChart(),
        ],
      );
    }

    // Desktop: two-column layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _ApplicationTrendBarChart(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _ApplicationStatusPieChart(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _UserRolePieChart(),
        ),
      ],
    );
  }

  // ─── Activity Section ───
  Widget _buildActivitySection(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _LiveActivityCard(
            title: 'New Users',
            icon: Icons.person_add_outlined,
            color: AppColors.primary,
            stream: context.read<AdminProvider>().getRecentUsers(limit: 4),
            itemBuilder: _buildUserTile,
          ),
          const SizedBox(height: 12),
          _LiveActivityCard(
            title: 'New Jobs',
            icon: Icons.work_outline,
            color: AppColors.accent,
            stream: context.read<AdminProvider>().getRecentJobs(limit: 4),
            itemBuilder: _buildJobTile,
          ),
          const SizedBox(height: 12),
          _LiveActivityCard(
            title: 'Recent Applications',
            icon: Icons.track_changes_outlined,
            color: AppColors.shortlisted,
            stream: context.read<AdminProvider>().getRecentApplications(limit: 4),
            itemBuilder: _buildApplicationTile,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LiveActivityCard(
            title: 'New Users',
            icon: Icons.person_add_outlined,
            color: AppColors.primary,
            stream: context.read<AdminProvider>().getRecentUsers(limit: 5),
            itemBuilder: _buildUserTile,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _LiveActivityCard(
            title: 'New Jobs',
            icon: Icons.work_outline,
            color: AppColors.accent,
            stream: context.read<AdminProvider>().getRecentJobs(limit: 5),
            itemBuilder: _buildJobTile,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _LiveActivityCard(
            title: 'Recent Applications',
            icon: Icons.track_changes_outlined,
            color: AppColors.shortlisted,
            stream: context.read<AdminProvider>().getRecentApplications(limit: 5),
            itemBuilder: _buildApplicationTile,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _ActivityTile(
      icon: Icons.person_outline_rounded,
      color: AppColors.primary,
      title: data['full_name'] ?? 'Unknown',
      subtitle: data['email'] ?? '',
      trailing: _formatDate(data['created_at']),
    );
  }

  Widget _buildJobTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _ActivityTile(
      icon: Icons.work_outline_rounded,
      color: AppColors.accent,
      title: data['title'] ?? 'Untitled',
      subtitle: data['company_name'] ?? '',
      trailing: _formatDate(data['created_at']),
    );
  }

  Widget _buildApplicationTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _ActivityTile(
      icon: Icons.person_outline_rounded,
      color: AppColors.shortlisted,
      title: data['seeker_name'] ?? 'Unknown',
      subtitle: data['job_title'] ?? '',
      trailing: _formatDate(data['applied_at']),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('MMM d').format(timestamp.toDate());
    }
    return '';
  }
}

// ─── Metric Data ───
class _MetricData {
  final String title;
  final Stream<int> stream;
  final IconData icon;
  final Color color;

  _MetricData(this.title, this.stream, this.icon, this.color);
}

// ─── Metric Card ───
class _MetricCard extends StatelessWidget {
  final String title;
  final Stream<int> stream;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.stream,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<int>(
                  stream: stream,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Application Status Pie Chart ───
class _ApplicationStatusPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Applications by Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<Map<String, int>>(
            stream: context.read<AdminProvider>().applicationStatusCounts,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text('No data',
                        style: TextStyle(color: AppColors.lightText)),
                  ),
                );
              }

              final data = snapshot.data!;
              final total = data.values.fold<int>(0, (a, b) => a + b);

              return Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: data.entries.map((e) {
                          final color = _getStatusColor(e.key);
                          final percentage =
                              total > 0 ? (e.value / total * 100) : 0.0;
                          return PieChartSectionData(
                            color: color,
                            value: e.value.toDouble(),
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: data.entries.map((e) {
                      final color = _getStatusColor(e.key);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_getStatusLabel(e.key)} (${e.value})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'applied': return AppColors.applied;
      case 'shortlisted': return AppColors.shortlisted;
      case 'interviewing': return AppColors.interviewing;
      case 'hired': return AppColors.hired;
      case 'rejected': return AppColors.rejected;
      default: return AppColors.lightText;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'applied': return 'Applied';
      case 'shortlisted': return 'Shortlisted';
      case 'interviewing': return 'Interviewing';
      case 'hired': return 'Hired';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }
}

// ─── Application Trend Bar Chart ───
class _ApplicationTrendBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Applications (Last 7 Days)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<MapEntry<String, int>>>(
            stream: context.read<AdminProvider>().applicationTrend,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text('No data',
                        style: TextStyle(color: AppColors.lightText)),
                  ),
                );
              }

              final data = snapshot.data!;
              final maxY = data.fold<int>(
                  0, (max, e) => e.value > max ? e.value : max);

              return SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxY + 2).toDouble(),
                    minY: 0,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${data[group.x].value}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                data[index].key,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.lightText,
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value == value.roundToDouble()) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.lightText,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 0 ? (maxY / 4) : 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.divider,
                        strokeWidth: 0.8,
                      ),
                    ),
                    barGroups: List.generate(data.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data[index].value.toDouble(),
                            color: AppColors.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── User Role Pie Chart ───
class _UserRolePieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users by Role',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<Map<String, int>>(
            stream: context.read<AdminProvider>().userRoleCounts,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text('No data',
                        style: TextStyle(color: AppColors.lightText)),
                  ),
                );
              }

              final data = snapshot.data!;
              final total = data.values.fold<int>(0, (a, b) => a + b);

              return Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: data.entries.map((e) {
                          final color = _getRoleColor(e.key);
                          final percentage =
                              total > 0 ? (e.value / total * 100) : 0.0;
                          return PieChartSectionData(
                            color: color,
                            value: e.value.toDouble(),
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 44,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: data.entries.map((e) {
                      final color = _getRoleColor(e.key);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_getRoleLabel(e.key)} (${e.value})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'job_seeker': return AppColors.accent;
      case 'recruiter': return AppColors.primary;
      case 'admin': return AppColors.shortlisted;
      default: return AppColors.lightText;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'job_seeker': return 'Job Seekers';
      case 'recruiter': return 'Recruiters';
      case 'admin': return 'Admins';
      default: return role;
    }
  }
}

// ─── Live Activity Card ───
class _LiveActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<List<QueryDocumentSnapshot>> stream;
  final Widget Function(QueryDocumentSnapshot) itemBuilder;

  const _LiveActivityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final docs = snapshot.data ?? [];

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No data yet',
                      style: TextStyle(
                        color: AppColors.lightText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) => itemBuilder(doc)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Activity Tile ───
class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;

  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.lightText,
              ),
            ),
        ],
      ),
    );
  }
}
