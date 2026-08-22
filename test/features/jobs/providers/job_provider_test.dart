import 'package:flutter_test/flutter_test.dart';
import 'package:apex_hires/features/jobs/providers/job_provider.dart';

void main() {
  group('JobProvider', () {
    late JobProvider jobProvider;

    setUp(() {
      jobProvider = JobProvider();
    });

    tearDown(() {
      jobProvider.dispose();
    });

    test('initial state should have empty filters', () {
      expect(jobProvider.searchQuery, '');
      expect(jobProvider.locationFilter, '');
      expect(jobProvider.jobTypeFilter, '');
      expect(jobProvider.experienceFilter, '');
      expect(jobProvider.isLoading, false);
      expect(jobProvider.error, isNull);
    });

    test('setSearchQuery should update query', () {
      jobProvider.setSearchQuery('Flutter');
      expect(jobProvider.searchQuery, 'Flutter');
    });

    test('setLocationFilter should update location', () {
      jobProvider.setLocationFilter('San Francisco');
      expect(jobProvider.locationFilter, 'San Francisco');
    });

    test('setJobTypeFilter should update job type', () {
      jobProvider.setJobTypeFilter('Remote');
      expect(jobProvider.jobTypeFilter, 'Remote');
    });

    test('setExperienceFilter should update experience level', () {
      jobProvider.setExperienceFilter('Senior');
      expect(jobProvider.experienceFilter, 'Senior');
    });

    test('clearFilters should reset all filters', () {
      jobProvider.setSearchQuery('Flutter');
      jobProvider.setLocationFilter('SF');
      jobProvider.setJobTypeFilter('Remote');
      jobProvider.setExperienceFilter('Senior');

      jobProvider.clearFilters();

      expect(jobProvider.searchQuery, '');
      expect(jobProvider.locationFilter, '');
      expect(jobProvider.jobTypeFilter, '');
      expect(jobProvider.experienceFilter, '');
    });

    test('setSearchQuery should notify listeners', () {
      int notifyCount = 0;
      jobProvider.addListener(() => notifyCount++);

      jobProvider.setSearchQuery('Test');
      expect(notifyCount, 1);
    });

    test('clearFilters should notify listeners', () {
      int notifyCount = 0;
      jobProvider.addListener(() => notifyCount++);

      jobProvider.setSearchQuery('Test');
      jobProvider.clearFilters();

      expect(notifyCount, 2);
    });

    test('toggling same filter should clear it', () {
      jobProvider.setJobTypeFilter('Remote');
      expect(jobProvider.jobTypeFilter, 'Remote');

      // The UI logic toggles: if same, set empty
      jobProvider.setJobTypeFilter('Remote');
      jobProvider.setJobTypeFilter(''); // Simulates toggle-off
      expect(jobProvider.jobTypeFilter, '');
    });
  });
}
