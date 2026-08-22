import 'package:flutter_test/flutter_test.dart';
import 'package:apex_hires/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('should have correct collection paths', () {
      expect(AppConstants.usersCollection, 'users');
      expect(AppConstants.jobsCollection, 'jobs');
      expect(AppConstants.applicationsCollection, 'applications');
      expect(AppConstants.chatsCollection, 'chats');
    });

    test('should have correct role constants', () {
      expect(AppConstants.roleJobSeeker, 'job_seeker');
      expect(AppConstants.roleRecruiter, 'recruiter');
      expect(AppConstants.roleAdmin, 'admin');
    });

    test('should have valid job types', () {
      expect(AppConstants.jobTypes, contains('Full-time'));
      expect(AppConstants.jobTypes, contains('Part-time'));
      expect(AppConstants.jobTypes, contains('Contract'));
      expect(AppConstants.jobTypes, contains('Remote'));
      expect(AppConstants.jobTypes, contains('Hybrid'));
      expect(AppConstants.jobTypes.length, 5);
    });

    test('should have valid experience levels', () {
      expect(AppConstants.experienceLevels, contains('Entry'));
      expect(AppConstants.experienceLevels, contains('Mid'));
      expect(AppConstants.experienceLevels, contains('Senior'));
      expect(AppConstants.experienceLevels, contains('Lead'));
      expect(AppConstants.experienceLevels.length, 4);
    });

    test('should have valid application statuses', () {
      expect(AppConstants.applicationStatuses, contains('applied'));
      expect(AppConstants.applicationStatuses, contains('shortlisted'));
      expect(AppConstants.applicationStatuses, contains('interviewing'));
      expect(AppConstants.applicationStatuses, contains('hired'));
      expect(AppConstants.applicationStatuses, contains('rejected'));
      expect(AppConstants.applicationStatuses.length, 5);
    });

    test('should have valid job statuses', () {
      expect(AppConstants.jobStatuses, contains('active'));
      expect(AppConstants.jobStatuses, contains('paused'));
      expect(AppConstants.jobStatuses, contains('closed'));
      expect(AppConstants.jobStatuses.length, 3);
    });

    test('should have common currencies', () {
      expect(AppConstants.currencies, contains('USD'));
      expect(AppConstants.currencies, contains('EUR'));
      expect(AppConstants.currencies, contains('GBP'));
    });
  });
}
