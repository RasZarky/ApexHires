import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/features/admin/screens/admin_dashboard_screen.dart';
import 'package:apex_hires/features/admin/screens/admin_users_screen.dart';
import 'package:apex_hires/features/admin/screens/admin_jobs_screen.dart';
import 'package:apex_hires/features/admin/screens/admin_applications_screen.dart';
import 'package:apex_hires/features/admin/providers/admin_provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard'),
    _NavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Users'),
    _NavItem(
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        label: 'Jobs'),
    _NavItem(
        icon: Icons.track_changes_outlined,
        activeIcon: Icons.track_changes,
        label: 'Applications'),
  ];

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminJobsScreen(),
    AdminApplicationsScreen(),
  ];

  void _showCreateAdminDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.shortlisted, Color(0xFF7C3AED)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Create Admin Account',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'New admins will have full access to the admin console including user management, job moderation, and analytics.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full Name
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 8) return 'Password must be at least 8 characters';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.lightText,
                              ),
                              onPressed: () {
                                setDialogState(() => obscurePassword = !obscurePassword);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) return;
                                        setDialogState(() => isLoading = true);

                                        final success = await context
                                            .read<AdminProvider>()
                                            .createAdminAccount(
                                              email: emailController.text.trim(),
                                              password: passwordController.text,
                                              fullName: nameController.text.trim(),
                                            );

                                        setDialogState(() => isLoading = false);

                                        if (success && context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Admin account created for ${emailController.text.trim()}',
                                              ),
                                              backgroundColor: AppColors.success,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        } else if (context.mounted) {
                                          final error = context.read<AdminProvider>().error;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(error ?? 'Failed to create admin'),
                                              backgroundColor: AppColors.error,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.shortlisted,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of the admin console?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName ?? 'Admin';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    return PopScope(
      canPop: false,
      child: Scaffold(
        // ─── Mobile: FAB for adding admin ───
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
                onPressed: _showCreateAdminDialog,
                backgroundColor: AppColors.shortlisted,
                tooltip: 'Create Admin',
                child: const Icon(Icons.person_add_rounded, color: Colors.white),
              )
            : null,
        // ─── Mobile: bottom navigation bar ───
        bottomNavigationBar: isDesktop
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        // Nav items
                        ...List.generate(_navItems.length, (index) {
                          final item = _navItems[index];
                          final isSelected = _selectedIndex == index;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedIndex = index),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected
                                        ? item.activeIcon
                                        : item.icon,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.lightText,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
        body: Row(
          children: [
            // ─── Sidebar (desktop only) ───
            if (isDesktop)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 260,
                color: AppColors.darkText,
                child: Column(
                  children: [
                    // Logo header
                    Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              width: 22,
                              height: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ApexHires',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Admin Console',
                                  style: TextStyle(
                                    color: AppColors.lightText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),

                    // Section label
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'NAVIGATION',
                          style: TextStyle(
                            color: AppColors.lightText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Navigation items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        itemCount: _navItems.length,
                        itemBuilder: (context, index) {
                          final item = _navItems[index];
                          final isSelected = _selectedIndex == index;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Material(
                              color: isSelected
                                  ? AppColors.primary.withAlpha(30)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () =>
                                    setState(() => _selectedIndex = index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? item.activeIcon
                                            : item.icon,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.lightText,
                                        size: 21,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.lightText,
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Add Admin Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: Material(
                        color: AppColors.shortlisted.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _showCreateAdminDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(
                              children: [
                                Icon(Icons.person_add_outlined, color: AppColors.shortlisted, size: 21),
                                SizedBox(width: 12),
                                Text(
                                  'Add Admin',
                                  style: TextStyle(
                                    color: AppColors.shortlisted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white12, height: 1),

                    // User info + logout
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white12),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                AppColors.primary.withAlpha(40),
                            child: Text(
                              userInitial,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: _confirmLogout,
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.lightText,
                              size: 20,
                            ),
                            tooltip: 'Sign Out',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Main content area ───
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
