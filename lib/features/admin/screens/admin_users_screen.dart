import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/admin/providers/admin_provider.dart';
import 'package:apex_hires/models/user_model.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _roleFilter = 'all';

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
            // Header
            Text(
              'User Management',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Manage accounts, verify recruiters, and moderate activity',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Filters
            if (isMobile)
              Column(
                children: [
                  CustomSearchBar(
                    hintText: 'Search by name or email...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 12),                    DropdownButtonFormField<String>(
                    initialValue: _roleFilter,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Roles')),
                      DropdownMenuItem(
                          value: 'job_seeker', child: Text('Job Seekers')),
                      DropdownMenuItem(
                          value: 'recruiter', child: Text('Recruiters')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    ],
                    onChanged: (v) => setState(() => _roleFilter = v ?? 'all'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomSearchBar(
                      hintText: 'Search users by name or email...',
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _roleFilter,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Roles')),
                        DropdownMenuItem(
                            value: 'job_seeker', child: Text('Job Seekers')),
                        DropdownMenuItem(
                            value: 'recruiter', child: Text('Recruiters')),
                        DropdownMenuItem(
                            value: 'admin', child: Text('Admins')),
                      ],
                      onChanged: (v) =>
                          setState(() => _roleFilter = v ?? 'all'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Users list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var users = snapshot.data?.docs
                          .map((doc) => UserModel.fromMap(
                              doc.data() as Map<String, dynamic>))
                          .toList() ??
                      [];

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    users = users
                        .where((u) =>
                            u.fullName.toLowerCase().contains(q) ||
                            u.email.toLowerCase().contains(q))
                        .toList();
                  }

                  // Apply role filter
                  if (_roleFilter != 'all') {
                    users =
                        users.where((u) => u.role == _roleFilter).toList();
                  }

                  if (users.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No users found',
                      subtitle: 'Try adjusting your search filters',
                    );
                  }

                  if (isMobile) {
                    return _buildMobileUserList(users);
                  }
                  return _buildDesktopUserTable(users);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mobile: card list ───
  Widget _buildMobileUserList(List<UserModel> users) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _MobileUserCard(user: user);
      },
    );
  }

  // ─── Desktop: table ───
  Widget _buildDesktopUserTable(List<UserModel> users) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Table header
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
                    child: Text('User',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 1,
                    child: Text('Role',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Expanded(
                    flex: 1,
                    child: Text('Joined',
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
          // Table rows
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _DesktopUserRow(user: users[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile user card ───
class _MobileUserCard extends StatelessWidget {
  final UserModel user;

  const _MobileUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.read<AdminProvider>();

    Color roleColor;
    String roleLabel;
    switch (user.role) {
      case 'recruiter':
        roleColor = AppColors.primary;
        roleLabel = 'Recruiter';
        break;
      case 'admin':
        roleColor = AppColors.shortlisted;
        roleLabel = 'Admin';
        break;
      default:
        roleColor = AppColors.accent;
        roleLabel = 'Job Seeker';
    }

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
              ProfileAvatar(
                url: user.avatarUrl,
                radius: 20,
                initials: user.fullName.isNotEmpty
                    ? user.fullName.substring(0, 1).toUpperCase()
                    : 'U',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.lightText,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Joined ${DateFormat('MMM d, yyyy').format(user.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightText,
                ),
              ),
              const Spacer(),
              if (user.role == 'recruiter')
                OutlinedButton(
                  onPressed: () async {
                    if (user.recruiterProfile?.isVerified == true) {
                      await adminProvider.unverifyRecruiter(user.uid);
                    } else {
                      await adminProvider.verifyRecruiter(user.uid);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: Text(
                    user.recruiterProfile?.isVerified == true
                        ? 'Unverify'
                        : 'Verify',
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
                      title: const Text('Block User'),
                      content: Text(
                          'Are you sure you want to block ${user.fullName}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Block',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await adminProvider.blockUser(user.uid);
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
                    const Text('Block', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Desktop user row ───
class _DesktopUserRow extends StatelessWidget {
  final UserModel user;

  const _DesktopUserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.read<AdminProvider>();

    Color roleColor;
    String roleLabel;

    switch (user.role) {
      case 'recruiter':
        roleColor = AppColors.primary;
        roleLabel = 'Recruiter';
        break;
      case 'admin':
        roleColor = AppColors.shortlisted;
        roleLabel = 'Admin';
        break;
      default:
        roleColor = AppColors.accent;
        roleLabel = 'Job Seeker';
    }

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
            child: Row(
              children: [
                ProfileAvatar(
                  url: user.avatarUrl,
                  radius: 18,
                  initials: user.fullName.isNotEmpty
                      ? user.fullName.substring(0, 1).toUpperCase()
                      : 'U',
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AppColors.lightText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('MMM d, yyyy').format(user.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (user.role == 'recruiter')
                  OutlinedButton(
                    onPressed: () async {
                      if (user.recruiterProfile?.isVerified == true) {
                        await adminProvider.unverifyRecruiter(user.uid);
                      } else {
                        await adminProvider.verifyRecruiter(user.uid);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(
                      user.recruiterProfile?.isVerified == true
                          ? 'Unverify'
                          : 'Verify',
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
                        title: const Text('Block User'),
                        content: Text(
                            'Are you sure you want to block ${user.fullName}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Block',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await adminProvider.blockUser(user.uid);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: AppColors.error),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Block',
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
