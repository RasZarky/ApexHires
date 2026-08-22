import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/features/recruiter/screens/recruiter_dashboard_screen.dart';
import 'package:apex_hires/features/recruiter/screens/my_jobs_screen.dart';
import 'package:apex_hires/features/chat/screens/chat_list_screen.dart';
import 'package:apex_hires/features/auth/screens/profile_screen.dart';
import 'package:apex_hires/core/widgets/unread_badge.dart';

class RecruiterHomeScreen extends StatefulWidget {
  const RecruiterHomeScreen({super.key});

  @override
  State<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends State<RecruiterHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseGlow;

  final List<Widget> _screens = const [
    RecruiterDashboardScreen(),
    MyJobsScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();

    // Pulse animation for shield icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseGlow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userId = user?.uid ?? '';
    final isVerified =
        user?.recruiterProfile?.isVerified == true;

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          // ─── Main app content ───
          Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    isVerified ? Icons.work_outline : Icons.work_off_outlined,
                  ),
                  activeIcon: Icon(
                    isVerified ? Icons.work : Icons.work_off,
                  ),
                  label: 'My Jobs',
                ),
                BottomNavigationBarItem(
                  icon: UnreadMessageBadge(
                    userId: userId,
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  activeIcon: UnreadMessageBadge(
                    userId: userId,
                    child: const Icon(Icons.chat_bubble),
                  ),
                  label: 'Messages',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),

          // ─── Verification overlay (non-dismissible) ───
          if (!isVerified)
            FadeTransition(
              opacity: _fadeAnim,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  color: AppColors.darkText.withAlpha(180),
                child: SafeArea(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Animated pulsing icon
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.warning,
                                            Color(0xFFF97316),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.warning.withAlpha((_pulseGlow.value * 80).toInt()),
                                            blurRadius: 20 + (_pulseGlow.value * 12),
                                            spreadRadius: _pulseGlow.value * 4,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Transform.scale(
                                        scale: _pulseScale.value,
                                        child: const Icon(
                                          Icons.shield_outlined,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Title
                                const Text(
                                  'Account Pending\nVerification',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkText,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Description
                                const Text(
                                  "Your recruiter account is currently under review by our admin team. You'll be able to post jobs and receive applications once verified.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.secondaryText,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Status timeline
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      _TimelineStep(
                                        icon: Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        label: 'Account Created',
                                        isCompleted: true,
                                      ),
                                      _TimelineConnector(
                                        color: AppColors.warning.withAlpha(60),
                                      ),
                                      _TimelineStep(
                                        icon: Icons.hourglass_top_rounded,
                                        color: AppColors.warning,
                                        label: 'Admin Review',
                                        isCompleted: false,
                                        isActive: true,
                                      ),
                                      _TimelineConnector(
                                        color: AppColors.divider,
                                      ),
                                      _TimelineStep(
                                        icon: Icons.work_outline_rounded,
                                        color: AppColors.lightText,
                                        label: 'Start Posting Jobs',
                                        isCompleted: false,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Info note
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withAlpha(15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.info.withAlpha(40),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: AppColors.info,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Verification typically takes 24-48 hours.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.info,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Refresh button
                                _RefreshButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Timeline step widget ───
class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isCompleted;
  final bool isActive;

  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.label,
    this.isCompleted = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(isActive ? 30 : (isCompleted ? 25 : 10)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.darkText : AppColors.secondaryText,
            ),
          ),
        ),
        if (isActive)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

// ─── Refresh Button ───
class _RefreshButton extends StatefulWidget {
  const _RefreshButton();

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final auth = context.read<AuthProvider>();
    await auth.refreshUser();
    if (!mounted) return;

    final isVerified = auth.user?.recruiterProfile?.isVerified == true;
    setState(() => _isRefreshing = false);

    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 You\'re verified! Welcome aboard.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Still pending verification. Check again later.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isRefreshing ? null : _handleRefresh,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primary),
        ),
        icon: _isRefreshing
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 20),
        label: Text(
          _isRefreshing ? 'Checking...' : 'Check Verification Status',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Timeline connector ───
class _TimelineConnector extends StatelessWidget {
  final Color color;

  const _TimelineConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
