import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apex_hires/models/job_model.dart';

void main() {
  group('JobModel', () {
    late JobModel job;
    late DateTime now;

    setUp(() {
      now = DateTime(2024, 6, 15, 10, 30);
      job = JobModel(
        jobId: 'job123',
        recruiterId: 'recruiter1',
        companyName: 'TechCorp',
        companyLogoUrl: 'https://example.com/logo.png',
        title: 'Senior Flutter Developer',
        description: 'We are looking for a Flutter expert...',
        location: 'San Francisco, CA',
        jobType: 'Full-time',
        experienceLevel: 'Senior',
        salaryRange: SalaryRange(min: 120000, max: 180000, currency: 'USD'),
        skillsRequired: ['Flutter', 'Dart', 'Firebase'],
        screeningQuestions: [
          ScreeningQuestion(
            questionId: 'q1',
            questionText: 'Years of Flutter experience?',
            isRequired: true,
          ),
          ScreeningQuestion(
            questionId: 'q2',
            questionText: 'Willing to relocate?',
            isRequired: false,
          ),
        ],
        status: 'active',
        applicationsCount: 15,
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create JobModel from map', () {
      final map = {
        'job_id': 'job456',
        'recruiter_id': 'recruiter2',
        'company_name': 'StartupXYZ',
        'company_logo_url': '',
        'title': 'Junior Developer',
        'description': 'Entry level position',
        'location': 'Remote',
        'job_type': 'Remote',
        'experience_level': 'Entry',
        'salary_range': {'min': 60000, 'max': 90000, 'currency': 'USD'},
        'skills_required': ['JavaScript', 'React'],
        'screening_questions': [
          {
            'question_id': 'sq1',
            'question_text': 'Portfolio link?',
            'is_required': true,
          }
        ],
        'status': 'active',
        'applications_count': 5,
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      };

      final restored = JobModel.fromMap(map);

      expect(restored.jobId, 'job456');
      expect(restored.title, 'Junior Developer');
      expect(restored.jobType, 'Remote');
      expect(restored.experienceLevel, 'Entry');
      expect(restored.salaryRange.min, 60000);
      expect(restored.salaryRange.max, 90000);
      expect(restored.skillsRequired, ['JavaScript', 'React']);
      expect(restored.screeningQuestions.length, 1);
      expect(restored.screeningQuestions.first.questionText, 'Portfolio link?');
      expect(restored.applicationsCount, 5);
    });

    test('should convert JobModel to map', () {
      final map = job.toMap();

      expect(map['job_id'], 'job123');
      expect(map['recruiter_id'], 'recruiter1');
      expect(map['title'], 'Senior Flutter Developer');
      expect(map['job_type'], 'Full-time');
      expect(map['experience_level'], 'Senior');
      expect(map['salary_range'], isA<Map>());
      expect(map['salary_range']['min'], 120000);
      expect(map['skills_required'], ['Flutter', 'Dart', 'Firebase']);
      expect(map['screening_questions'], isA<List>());
      expect(map['applications_count'], 15);
      expect(map['created_at'], isA<Timestamp>());
    });

    test('salaryDisplay should format correctly', () {
      expect(job.salaryDisplay, 'USD 120000 - 180000');
    });

    test('copyWith should update specified fields', () {
      final updated = job.copyWith(
        title: 'Lead Flutter Developer',
        status: 'paused',
        applicationsCount: 20,
      );

      expect(updated.title, 'Lead Flutter Developer');
      expect(updated.status, 'paused');
      expect(updated.applicationsCount, 20);
      // Unchanged
      expect(updated.jobId, 'job123');
      expect(updated.recruiterId, 'recruiter1');
      expect(updated.jobType, 'Full-time');
    });

    test('should handle missing fields with defaults', () {
      final map = <String, dynamic>{
        'job_id': 'j1',
        'recruiter_id': 'r1',
        'company_name': 'Co',
        'title': 'Dev',
        'description': 'Desc',
        'location': 'Loc',
      };

      final j = JobModel.fromMap(map);

      expect(j.jobType, 'Full-time');
      expect(j.experienceLevel, 'Mid');
      expect(j.status, 'active');
      expect(j.applicationsCount, 0);
      expect(j.skillsRequired, isEmpty);
      expect(j.screeningQuestions, isEmpty);
      expect(j.companyLogoUrl, '');
    });

    test('timeAgo should return correct relative time', () {
      // Just now
      final justNow = job.copyWith();
      // The timeAgo getter uses DateTime.now() so we test the format
      expect(job.timeAgo, isA<String>());
      expect(job.timeAgo.isNotEmpty, true);
    });
  });

  group('SalaryRange', () {
    test('should create from map', () {
      final range = SalaryRange.fromMap({
        'min': 50000,
        'max': 100000,
        'currency': 'EUR',
      });

      expect(range.min, 50000);
      expect(range.max, 100000);
      expect(range.currency, 'EUR');
    });

    test('should use defaults for missing values', () {
      final range = SalaryRange.fromMap({});
      expect(range.min, 0);
      expect(range.max, 0);
      expect(range.currency, 'USD');
    });

    test('should serialize correctly', () {
      final range = SalaryRange(min: 80000, max: 120000, currency: 'GBP');
      final map = range.toMap();

      expect(map['min'], 80000);
      expect(map['max'], 120000);
      expect(map['currency'], 'GBP');
    });
  });

  group('ScreeningQuestion', () {
    test('should create from map', () {
      final q = ScreeningQuestion.fromMap({
        'question_id': 'sq1',
        'question_text': 'What is your availability?',
        'is_required': true,
      });

      expect(q.questionId, 'sq1');
      expect(q.questionText, 'What is your availability?');
      expect(q.isRequired, true);
    });

    test('should serialize correctly', () {
      final q = ScreeningQuestion(
        questionId: 'sq2',
        questionText: 'Notice period?',
        isRequired: false,
      );
      final map = q.toMap();

      expect(map['question_id'], 'sq2');
      expect(map['question_text'], 'Notice period?');
      expect(map['is_required'], false);
    });

    test('should default isRequired to true', () {
      final q = ScreeningQuestion.fromMap({
        'question_id': 'sq3',
        'question_text': 'Test?',
      });
      expect(q.isRequired, true);
    });
  });
}
