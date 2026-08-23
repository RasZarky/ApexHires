import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/jobs/screens/job_search_screen.dart';
import 'package:apex_hires/features/applications/screens/application_tracker_screen.dart';
import 'package:apex_hires/features/chat/screens/chat_list_screen.dart';
import 'package:apex_hires/features/auth/screens/profile_screen.dart';
import 'package:apex_hires/core/widgets/unread_badge.dart';

class SeekerHomeScreen extends StatefulWidget {
  const SeekerHomeScreen({super.key});

  @override
  State<SeekerHomeScreen> createState() => _SeekerHomeScreenState();
}

class _SeekerHomeScreenState extends State<SeekerHomeScreen> {
  int _currentIndex = 0;

  void _navigateToJobs() => setState(() => _currentIndex = 0);

  late final List<Widget> _screens = [
    const JobSearchScreen(),
    ApplicationTrackerScreen(onNavigateToJobs: _navigateToJobs),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.uid ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Jobs',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.track_changes_outlined),
              activeIcon: Icon(Icons.track_changes),
              label: 'Applications',
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
    );
  }
}
