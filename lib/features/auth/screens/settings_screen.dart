import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/auth/screens/developer_options_screen.dart';
import 'package:apex_hires/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _buildTapCount = 0;

  void _onBuildNumberTap() {
    final auth = context.read<AuthProvider>();
    if (auth.developerUnlocked) return;
    _buildTapCount++;

    if (_buildTapCount >= 7) {
      auth.unlockDeveloperMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 You are now a developer!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_buildTapCount >= 3) {
      final remaining = 7 - _buildTapCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tap $remaining more times to become a developer'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Account Section
          _SectionHeader('Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Account Info',
            subtitle: '${user?.email ?? ''} • ${_roleLabel(user?.role)}',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_reset_outlined,
            title: 'Forgot Password',
            subtitle: 'Send a password reset email',
            onTap: () async {
              final email = user?.email ?? '';
              if (email.isEmpty) return;
              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.sendPasswordResetEmail(email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Password reset email sent to $email'
                          : 'Failed to send reset email',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 8),

          // App Section
          _SectionHeader('App'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About ApexHires',
            subtitle: 'Version 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ApexHires',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                children: const [
                  Text(
                    'ApexHires is a streamlined job recruitment platform '
                    'focusing on job matching, candidate tracking, and '
                    'recruitment messaging.',
                  ),
                ],
              );
            },
          ),
          Builder(
            builder: (context) {
              final isDev = context.watch<AuthProvider>().developerUnlocked;
              return GestureDetector(
                onTap: isDev
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeveloperOptionsScreen(),
                          ),
                        );
                      }
                    : _onBuildNumberTap,
                child: _SettingsTile(
                  icon: isDev ? Icons.developer_mode : Icons.code,
                  title: 'Build Number',
                  subtitle: isDev
                      ? '1 (Developer mode enabled)'
                      : '1',
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.gavel_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),

          const SizedBox(height: 8),

          // Danger Zone
          _SectionHeader('Danger Zone'),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            titleColor: AppColors.error,
            onTap: () async {
              final reasonController = TextEditingController();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Delete Account'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Are you sure you want to delete your account? An admin can recover it if needed.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          hintText: 'Reason for deletion (optional)',
                          isDense: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                final authProvider = context.read<AuthProvider>();
                final success = await authProvider.deleteAccount(
                  reason: reasonController.text.trim(),
                );
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted. You will be signed out.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.of(context).pushReplacementNamed('/welcome');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete account.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'job_seeker':
        return 'Job Seeker';
      case 'recruiter':
        return 'Recruiter';
      case 'admin':
        return 'Admin';
      default:
        return 'Unknown';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? AppColors.secondaryText),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? AppColors.darkText,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: AppColors.lightText)
            : null,
        onTap: onTap,
      ),
    );
  }
}


