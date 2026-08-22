import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';
import 'package:apex_hires/features/auth/screens/role_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget makeTestable() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const RoleSelectionScreen(),
      ),
    );
  }

  group('RoleSelectionScreen', () {
    testWidgets('should display welcome message', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.pump();

      expect(find.text('Welcome to ApexHires'), findsOneWidget);
      expect(
        find.text('Choose how you want to use the platform'),
        findsOneWidget,
      );
    });

    testWidgets('should show both role options', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.pump();

      expect(find.text('Job Seeker'), findsOneWidget);
      expect(find.text('Recruiter'), findsOneWidget);
    });

    testWidgets('should have Continue button', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.pump();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('should show role descriptions', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.pump();

      expect(
        find.text(
          'Find your dream job, build your profile, and track applications',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Post jobs, manage candidates, and find the best talent',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display app logo icon', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.pump();

      expect(find.byIcon(Icons.work_rounded), findsOneWidget);
    });

    testWidgets('should display role icons', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.pump();

      expect(find.byIcon(Icons.person_search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.business_center_rounded), findsOneWidget);
    });

    testWidgets('should select Job Seeker role on tap', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.pump();

      await tester.tap(find.text('Job Seeker'));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('should select Recruiter role on tap', (tester) async {
      await tester.pumpWidget(makeTestable());
      await tester.pump();

      await tester.tap(find.text('Recruiter'));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
