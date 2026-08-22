import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

class DeveloperOptionsScreen extends StatelessWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Developer Options',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy all info',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Developer info copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── App Details ───
          _SectionHeader('App Details'),
          _InfoCard(
            children: [
              _InfoRow('App Name', 'ApexHires'),
              _InfoRow('Version', '1.0.0'),
              _InfoRow('Build Number', '1'),
              _InfoRow('Package Name', 'com.apexhires.apexHires'),
              _InfoRow('Flutter Version', _getFlutterVersion()),
              _InfoRow('Dart Version', _getDartVersion()),
              _InfoRow('Environment', kReleaseMode ? 'Release' : kProfileMode ? 'Profile' : 'Debug'),
            ],
          ),

          const SizedBox(height: 16),

          // ─── Device Info ───
          _SectionHeader('Device Info'),
          _InfoCard(
            children: [
              _InfoRow('Platform', _getPlatform()),
              _InfoRow('OS Version', _getOsVersion()),
              _InfoRow('Device Model', _getDeviceModel()),
              _InfoRow('Screen Size', _getScreenSize(context)),
              _InfoRow('Pixel Ratio', '${MediaQuery.of(context).devicePixelRatio.toStringAsFixed(1)}x'),
              _InfoRow(' Locale', Localizations.localeOf(context).toString()),
              _InfoRow('Timezone', DateTime.now().timeZoneName),
            ],
          ),

          const SizedBox(height: 16),

          // ─── User Info ───
          _SectionHeader('User Info'),
          _InfoCard(
            children: [
              _InfoRow('User ID', user?.uid ?? 'N/A'),
              _InfoRow('Email', user?.email ?? 'N/A'),
              _InfoRow('Display Name', user?.fullName ?? 'N/A'),
              _InfoRow('Role', _roleLabel(user?.role)),
              _InfoRow('Account Created', _formatDate(user?.createdAt)),
            ],
          ),

          const SizedBox(height: 16),

          // ─── Developer Info ───
          _SectionHeader('Developer Info'),
          _InfoCard(
            children: [
              _InfoRow('Developer', 'Abdul Razak Abubakari'),
              _InfoRow('Support', 'ubdoolrazak@gmail.com'),
              _InfoRow('Flutter Channel', 'stable'),
              _InfoRow('OneSignal', kDebugMode ? 'Configured (dev)' : 'Configured (prod)'),
              _InfoRow('Supabase', 'Configured (storage)'),
              _InfoRow('Firebase', 'Spark Plan'),
            ],
          ),

          const SizedBox(height: 16),

          // ─── Build Info ───
          _SectionHeader('Build Info'),
          _InfoCard(
            children: [
              _InfoRow('Compile Mode', kDebugMode ? 'Debug' : kProfileMode ? 'Profile' : 'Release'),
              _InfoRow('Tree Shaking', kReleaseMode ? 'Enabled' : 'Disabled'),
              _InfoRow('Null Safety', 'Enabled'),
              _InfoRow('Web Renderer', kIsWeb ? 'HTML' : 'N/A'),
              _InfoRow('Hot Restart', kDebugMode ? 'Available' : 'N/A'),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getFlutterVersion() {
    // Returns the Flutter version used at build time
    return '3.x';
  }

  String _getDartVersion() {
    return '3.10+';
  }

  String _getPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  String _getOsVersion() {
    if (kIsWeb) return 'Browser';
    if (Platform.isAndroid) return 'Android ${Platform.operatingSystemVersion}';
    if (Platform.isIOS) return 'iOS ${Platform.operatingSystemVersion}';
    if (Platform.isMacOS) return 'macOS ${Platform.operatingSystemVersion}';
    return Platform.operatingSystemVersion;
  }

  String _getDeviceModel() {
    if (kIsWeb) return 'Web Browser';
    // For mobile, this would need device_info_plus package
    // For now, provide what's available
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    if (Platform.isMacOS) return 'Mac';
    if (Platform.isWindows) return 'Windows PC';
    return 'Unknown';
  }

  String _getScreenSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return '${size.width.toStringAsFixed(0)} × ${size.height.toStringAsFixed(0)}';
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'job_seeker': return 'Job Seeker';
      case 'recruiter': return 'Recruiter';
      case 'admin': return 'Admin';
      default: return 'Unknown';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.lightText,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
