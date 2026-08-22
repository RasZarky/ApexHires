import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_hires/core/theme/app_theme.dart';
import 'package:apex_hires/core/widgets/common_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  Widget makeTestable(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('StatusBadge', () {
    testWidgets('should display correct label for applied status', (tester) async {
      await tester.pumpWidget(makeTestable(const StatusBadge(status: 'applied')));
      expect(find.text('Applied'), findsOneWidget);
    });

    testWidgets('should display correct label for shortlisted status', (tester) async {
      await tester.pumpWidget(makeTestable(const StatusBadge(status: 'shortlisted')));
      expect(find.text('Shortlisted'), findsOneWidget);
    });

    testWidgets('should display correct label for interviewing status', (tester) async {
      await tester.pumpWidget(makeTestable(const StatusBadge(status: 'interviewing')));
      expect(find.text('Interviewing'), findsOneWidget);
    });

    testWidgets('should display correct label for hired status', (tester) async {
      await tester.pumpWidget(makeTestable(const StatusBadge(status: 'hired')));
      expect(find.text('Hired'), findsOneWidget);
    });

    testWidgets('should display correct label for rejected status', (tester) async {
      await tester.pumpWidget(makeTestable(const StatusBadge(status: 'rejected')));
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('small badge should render without error', (tester) async {
      await tester.pumpWidget(makeTestable(
        const StatusBadge(status: 'applied', small: true),
      ));
      expect(find.text('Applied'), findsOneWidget);
    });
  });

  group('SkillChip', () {
    testWidgets('should display skill text', (tester) async {
      await tester.pumpWidget(makeTestable(
        const SkillChip(skill: 'Flutter'),
      ));
      expect(find.text('Flutter'), findsOneWidget);
    });

    testWidgets('should show selected state', (tester) async {
      await tester.pumpWidget(makeTestable(
        const SkillChip(skill: 'Dart', selected: true),
      ));
      expect(find.text('Dart'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(makeTestable(
        SkillChip(
          skill: 'Firebase',
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Firebase'));
      expect(tapped, true);
    });
  });

  group('EmptyState', () {
    testWidgets('should display title and subtitle', (tester) async {
      await tester.pumpWidget(makeTestable(
        const EmptyState(
          icon: Icons.work_off_outlined,
          title: 'No jobs found',
          subtitle: 'Try adjusting your filters',
        ),
      ));

      expect(find.text('No jobs found'), findsOneWidget);
      expect(find.text('Try adjusting your filters'), findsOneWidget);
      expect(find.byIcon(Icons.work_off_outlined), findsOneWidget);
    });

    testWidgets('should show action button when provided', (tester) async {
      bool actionPressed = false;
      await tester.pumpWidget(makeTestable(
        EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Empty',
          subtitle: 'Nothing here',
          actionLabel: 'Refresh',
          onAction: () => actionPressed = true,
        ),
      ));

      expect(find.text('Refresh'), findsOneWidget);
      await tester.tap(find.text('Refresh'));
      expect(actionPressed, true);
    });

    testWidgets('should hide action button when not provided', (tester) async {
      await tester.pumpWidget(makeTestable(
        const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Empty',
          subtitle: 'Nothing here',
        ),
      ));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('ProfileAvatar', () {
    testWidgets('should show initials when no URL', (tester) async {
      await tester.pumpWidget(makeTestable(
        const ProfileAvatar(
          url: '',
          radius: 24,
          initials: 'JD',
        ),
      ));

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('should show CircleAvatar', (tester) async {
      await tester.pumpWidget(makeTestable(
        const ProfileAvatar(
          url: '',
          radius: 32,
          initials: 'AB',
        ),
      ));

      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });

  group('CustomSearchBar', () {
    testWidgets('should display hint text', (tester) async {
      await tester.pumpWidget(makeTestable(
        CustomSearchBar(
          hintText: 'Search jobs...',
          onChanged: (_) {},
        ),
      ));

      expect(find.text('Search jobs...'), findsOneWidget);
    });

    testWidgets('should display search icon', (tester) async {
      await tester.pumpWidget(makeTestable(
        CustomSearchBar(
          hintText: 'Search...',
          onChanged: (_) {},
        ),
      ));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should call onChanged when typing', (tester) async {
      String changedValue = '';
      await tester.pumpWidget(makeTestable(
        CustomSearchBar(
          hintText: 'Search...',
          onChanged: (v) => changedValue = v,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'Flutter');
      expect(changedValue, 'Flutter');
    });
  });

  group('SectionHeader', () {
    testWidgets('should display title', (tester) async {
      await tester.pumpWidget(makeTestable(
        const SectionHeader(title: 'Recent Jobs'),
      ));

      expect(find.text('Recent Jobs'), findsOneWidget);
    });

    testWidgets('should show action button when provided', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(makeTestable(
        SectionHeader(
          title: 'Jobs',
          actionLabel: 'See All',
          onAction: () => pressed = true,
        ),
      ));

      expect(find.text('See All'), findsOneWidget);
      await tester.tap(find.text('See All'));
      expect(pressed, true);
    });
  });
}
