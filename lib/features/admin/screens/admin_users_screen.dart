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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
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
                        DropdownMenuItem(value: 'admin', child: Text('Admins')),
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

  // --- Mobile: card list ---
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

  // --- Desktop: table ---
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
                    child: Text('Registered On',
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

// --- Mobile user card ---
class _MobileUserCard extends StatelessWidget {
  final UserModel user;

  const _MobileUserCard({required this.user});

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
              // 3-dot action menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(context, value, adminProvider),
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
                  if (user.role == 'recruiter')
                    PopupMenuItem(
                      value: 'verify',
                      child: Row(
                        children: [
                          Icon(
                            user.recruiterProfile?.isVerified == true
                                ? Icons.verified_outlined
                                : Icons.verified,
                            size: 18,
                            color: user.recruiterProfile?.isVerified == true
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Text(user.recruiterProfile?.isVerified == true
                              ? 'Unverify'
                              : 'Verify'),
                        ],
                      ),
                    ),
                  if (user.isBlocked)
                    const PopupMenuItem(
                      value: 'unblock',
                      child: Row(
                        children: [
                          Icon(Icons.lock_open, size: 18, color: AppColors.success),
                          SizedBox(width: 10),
                          Text('Unblock', style: TextStyle(color: AppColors.success)),
                        ],
                      ),
                    ),
                  if (!user.isBlocked)
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 18, color: AppColors.error),
                          SizedBox(width: 10),
                          Text('Block', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  if (user.isDeleted)
                    const PopupMenuItem(
                      value: 'recover',
                      child: Row(
                        children: [
                          Icon(Icons.replay, size: 18, color: AppColors.success),
                          SizedBox(width: 10),
                          Text('Recover Account', style: TextStyle(color: AppColors.success)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _RoleBadge(role: user.role),
              _StatusIndicator(isBlocked: user.isBlocked, isDeleted: user.isDeleted),
              Text(
                DateFormat('MMM d, yyyy').format(user.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String value, AdminProvider adminProvider) {
    switch (value) {
      case 'view':
        _showUserDetails(context, user);
        break;
      case 'verify':
        if (user.recruiterProfile?.isVerified == true) {
          adminProvider.unverifyRecruiter(user.uid);
        } else {
          adminProvider.verifyRecruiter(user.uid);
        }
        break;
      case 'block':
        _confirmBlock(context, adminProvider);
        break;
      case 'unblock':
        adminProvider.unblockUser(user.uid);
        break;
      case 'recover':
        _confirmRecover(context, adminProvider);
        break;
    }
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _UserDetailsSheet(
          user: user,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _confirmBlock(BuildContext context, AdminProvider adminProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await adminProvider.blockUser(user.uid);
    }
  }

  void _confirmRecover(BuildContext context, AdminProvider adminProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Recover Account'),
        content: Text('Are you sure you want to recover ${user.fullName}\'s deleted account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recover', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await adminProvider.recoverDeletedUser(user.uid);
    }
  }
}

// --- Desktop user row ---
class _DesktopUserRow extends StatelessWidget {
  final UserModel user;

  const _DesktopUserRow({required this.user});

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
          // User column
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.lightText,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Role column
          Expanded(
            flex: 1,
            child: _RoleBadge(role: user.role),
          ),
          // Registered On column
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
          // Status column
          Expanded(
            flex: 1,
            child: _StatusIndicator(isBlocked: user.isBlocked, isDeleted: user.isDeleted),
          ),
          // Actions column (3-dot menu)
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _showUserDetails(context, user);
                    break;
                  case 'verify':
                    if (user.recruiterProfile?.isVerified == true) {
                      adminProvider.unverifyRecruiter(user.uid);
                    } else {
                      adminProvider.verifyRecruiter(user.uid);
                    }
                    break;
                  case 'block':
                    _confirmBlock(context, adminProvider);
                    break;
                  case 'unblock':
                    adminProvider.unblockUser(user.uid);
                    break;
                  case 'recover':
                    _confirmRecover(context, adminProvider);
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
                if (user.role == 'recruiter')
                  PopupMenuItem(
                    value: 'verify',
                    child: Row(
                      children: [
                        Icon(
                          user.recruiterProfile?.isVerified == true
                              ? Icons.verified_outlined
                              : Icons.verified,
                          size: 18,
                          color: user.recruiterProfile?.isVerified == true
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        Text(user.recruiterProfile?.isVerified == true
                            ? 'Unverify'
                            : 'Verify'),
                      ],
                    ),
                  ),
                if (!user.isBlocked)
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Block', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                if (user.isBlocked)
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      children: [
                        Icon(Icons.lock_open, size: 18, color: AppColors.success),
                        SizedBox(width: 10),
                        Text('Unblock', style: TextStyle(color: AppColors.success)),
                      ],
                    ),
                  ),
                if (user.isDeleted)
                  const PopupMenuItem(
                    value: 'recover',
                    child: Row(
                      children: [
                        Icon(Icons.replay, size: 18, color: AppColors.success),
                        SizedBox(width: 10),
                        Text('Recover Account', style: TextStyle(color: AppColors.success)),
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

  void _showUserDetails(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _UserDetailsSheet(
          user: user,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _confirmBlock(BuildContext context, AdminProvider adminProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await adminProvider.blockUser(user.uid);
    }
  }

  void _confirmRecover(BuildContext context, AdminProvider adminProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Recover Account'),
        content: Text('Are you sure you want to recover ${user.fullName}\'s deleted account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recover', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await adminProvider.recoverDeletedUser(user.uid);
    }
  }
}

// --- Role badge ---
class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (role) {
      case 'recruiter':
        color = AppColors.primary;
        label = 'Recruiter';
        break;
      case 'admin':
        color = AppColors.shortlisted;
        label = 'Admin';
        break;
      default:
        color = AppColors.accent;
        label = 'Job Seeker';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --- Status indicator ---
class _StatusIndicator extends StatelessWidget {
  final bool isBlocked;
  final bool isDeleted;

  const _StatusIndicator({required this.isBlocked, this.isDeleted = false});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (isDeleted) {
      label = 'Deleted';
      color = AppColors.warning;
    } else if (isBlocked) {
      label = 'Blocked';
      color = AppColors.error;
    } else {
      label = 'Active';
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --- User details bottom sheet ---
class _UserDetailsSheet extends StatelessWidget {
  final UserModel user;
  final ScrollController scrollController;

  const _UserDetailsSheet({
    required this.user,
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

          // User avatar and name
          Center(
            child: Column(
              children: [
                ProfileAvatar(
                  url: user.avatarUrl,
                  radius: 36,
                  initials: user.fullName.isNotEmpty
                      ? user.fullName.substring(0, 1).toUpperCase()
                      : 'U',
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                  icon: Icons.person_outline,
                  label: 'Role',
                  value: user.role == 'job_seeker'
                      ? 'Job Seeker'
                      : user.role == 'recruiter'
                          ? 'Recruiter'
                          : 'Admin',
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Registered',
                  value: DateFormat('MMMM d, yyyy').format(user.createdAt),
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: user.isBlocked ? Icons.block : Icons.check_circle_outline,
                  label: 'Status',
                  value: user.isBlocked ? 'Blocked' : 'Active',
                  valueColor: user.isBlocked ? AppColors.error : AppColors.success,
                ),
                if (user.phoneNumber.isNotEmpty) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: user.phoneNumber,
                  ),
                ],
                if (user.role == 'recruiter' && user.recruiterProfile != null) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.business_outlined,
                    label: 'Company',
                    value: user.recruiterProfile!.companyName.isNotEmpty
                        ? user.recruiterProfile!.companyName
                        : 'N/A',
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.verified_outlined,
                    label: 'Verified',
                    value: user.recruiterProfile!.isVerified ? 'Yes' : 'No',
                    valueColor: user.recruiterProfile!.isVerified
                        ? AppColors.success
                        : AppColors.lightText,
                  ),
                ],
                if (user.role == 'job_seeker' && user.seekerProfile != null) ...[
                  if (user.seekerProfile!.headline.isNotEmpty) ...[
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.work_outline,
                      label: 'Headline',
                      value: user.seekerProfile!.headline,
                    ),
                  ],
                  if (user.seekerProfile!.location.isNotEmpty) ...[
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: user.seekerProfile!.location,
                    ),
                  ],
                  if (user.seekerProfile!.skills.isNotEmpty) ...[
                    const Divider(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_outline, size: 18, color: AppColors.lightText),
                            const SizedBox(width: 10),
                            Text(
                              'Skills',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: user.seekerProfile!.skills
                              .map((skill) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      skill,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
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
