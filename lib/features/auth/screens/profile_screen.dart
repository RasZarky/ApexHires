import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/auth/screens/edit_profile_screen.dart';
import 'package:apex_hires/features/auth/screens/settings_screen.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh user data from Firestore on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthProvider>().refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Column(
                  children: [
                    ProfileAvatar(
                      url: user?.avatarUrl ?? '',
                      radius: 48,
                      initials: user?.fullName.isNotEmpty == true
                          ? user!.fullName.substring(0, 1).toUpperCase()
                          : 'U',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (user?.seekerProfile?.headline.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.seekerProfile!.headline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                    if (user?.recruiterProfile != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${user!.recruiterProfile!.companyName} • ${user.recruiterProfile!.designation}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Seeker Profile Sections
              if (user?.role == 'job_seeker') ...[
                _ProfileSection(
                  title: 'About',
                  content: user?.seekerProfile?.bio.isNotEmpty == true
                      ? user!.seekerProfile!.bio
                      : 'No bio added yet. Tap Edit Profile to add one.',
                ),

                if (user?.seekerProfile?.location.isNotEmpty == true)
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    subtitle: user!.seekerProfile!.location,
                  ),

                if (user?.seekerProfile?.skills.isNotEmpty == true)
                  _ProfileSection(
                    title: 'Skills',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user!.seekerProfile!.skills
                          .map((skill) => SkillChip(skill: skill))
                          .toList(),
                    ),
                  ),

                if (user?.seekerProfile?.experience.isNotEmpty == true)
                  _ProfileSection(
                    title: 'Experience',
                    child: Column(
                      children: user!.seekerProfile!.experience
                          .map((exp) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.work_outline,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exp.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            exp.company,
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate}',
                                            style: const TextStyle(
                                              color: AppColors.lightText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                if (user?.seekerProfile?.education.isNotEmpty == true)
                  _ProfileSection(
                    title: 'Education',
                    child: Column(
                      children: user!.seekerProfile!.education
                          .map((edu) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.school_outlined,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            edu.degree,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            edu.institution,
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${edu.startYear} - ${edu.endYear}',
                                            style: const TextStyle(
                                              color: AppColors.lightText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],

              const SizedBox(height: 8),

              // Sign Out
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content:
                              const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await context.read<AuthProvider>().signOut();
                        Navigator.of(context)
                            .pushReplacementNamed('/welcome');
                      }
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? child;

  const _ProfileSection({
    required this.title,
    this.content,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
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
          if (content != null)
            Text(
              content!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.secondaryText,
              ),
            ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondaryText, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightText,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
