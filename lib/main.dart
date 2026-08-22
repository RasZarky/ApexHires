import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/jobs/providers/job_provider.dart';
import 'package:apex_hires/features/applications/providers/application_provider.dart';
import 'package:apex_hires/features/chat/providers/chat_provider.dart';

import 'package:apex_hires/features/auth/screens/splash_screen.dart';
import 'package:apex_hires/features/auth/screens/welcome_screen.dart';
import 'package:apex_hires/features/auth/screens/role_selection_screen.dart';
import 'package:apex_hires/features/auth/screens/login_screen.dart';
import 'package:apex_hires/features/auth/screens/signup_screen.dart';
import 'package:apex_hires/features/auth/screens/profile_setup_screen.dart';
import 'package:apex_hires/features/jobs/screens/seeker_home_screen.dart';
import 'package:apex_hires/features/recruiter/screens/recruiter_home_screen.dart';
import 'package:apex_hires/features/admin/screens/admin_shell_screen.dart';
import 'package:apex_hires/features/admin/screens/admin_login_screen.dart';
import 'package:apex_hires/features/admin/providers/admin_provider.dart';
import 'package:apex_hires/services/notification_service.dart';
import 'package:apex_hires/services/supabase_storage_service.dart' as supa;

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler (required by Firebase, OneSignal uses it too)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Supabase for file storage (free tier)
  await supa.StorageService.initialize();

  runApp(const ApexHiresApp());
}

class ApexHiresApp extends StatefulWidget {
  const ApexHiresApp({super.key});

  @override
  State<ApexHiresApp> createState() => _ApexHiresAppState();
}

class _ApexHiresAppState extends State<ApexHiresApp> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationSetup = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider();
            auth.init().then((_) {
              // Initialize OneSignal after auth completes
              if (auth.isLoggedIn && !_notificationSetup) {
                _notificationSetup = true;
                _notificationService.initialize(auth.user!.uid);
              }
            });
            return auth;
          },
        ),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'ApexHires',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/role_selection': (context) => const RoleSelectionScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/profile_setup': (context) => const ProfileSetupScreen(),
          '/seeker_home': (context) => const SeekerHomeScreen(),
          '/recruiter_home': (context) => const RecruiterHomeScreen(),
          '/admin': (context) => const AdminShellScreen(),
          '/admin/login': (context) => const AdminLoginScreen(),
        },
      ),
    );
  }
}
