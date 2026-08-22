import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Wait for animation + auth init, then navigate
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Wait for animation
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // Wait for auth init to complete
    while (auth.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;

    // Navigate based on auth state
    if (auth.isLoggedIn) {
      final user = auth.user;
      if (user != null) {
        // Check if profile is complete
        final hasProfile = _isProfileComplete(user);
        if (hasProfile) {
          // Go directly to home screen based on role
          if (user.role == 'admin') {
            Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
          } else if (user.role == 'recruiter') {
            Navigator.of(context).pushNamedAndRemoveUntil('/recruiter_home', (route) => false);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/seeker_home', (route) => false);
          }
          return;
        } else {
          // Profile incomplete — go to profile setup (but don't re-ask name/email)
          Navigator.of(context).pushReplacementNamed('/profile_setup');
          return;
        }
      }
    }

    // Not logged in
    if (kIsWeb) {
      // On web, show admin login directly
      Navigator.of(context).pushReplacementNamed('/admin/login');
    } else {
      // On mobile, show welcome screen
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  /// Check if the user's profile has the minimum required data
  bool _isProfileComplete(dynamic user) {
    if (user.fullName.isEmpty) return false;
    if (user.role == 'job_seeker') {
      return user.seekerProfile != null &&
          (user.seekerProfile!.headline.isNotEmpty ||
              user.seekerProfile!.bio.isNotEmpty);
    }
    if (user.role == 'recruiter') {
      return user.recruiterProfile != null &&
          user.recruiterProfile!.companyName.isNotEmpty;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ApexHires',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Recruitment, Simplified',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
