import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apex_hires/models/application_model.dart';

void main() {
  group('ApplicationModel', () {
    late ApplicationModel application;
    late DateTime now;

    setUp(() {
      now = DateTime(2024, 8, 1);
      application = ApplicationModel(
        applicationId: 'app1',
        jobId: 'job1',
        jobTitle: 'Flutter Developer',
        recruiterId: 'recruiter1',
        seekerId: 'seeker1',
        seekerName: 'Alice Johnson',
        seekerAvatar: 'https://example.com/alice.jpg',
        seekerHeadline: 'Mobile Developer',
        resumeUrl: 'https://example.com/resume.pdf',
        status: 'applied',
        screeningAnswers: [
          ScreeningAnswer(
            questionText: 'Years of experience?',
            answerText: '5 years',
          ),
          ScreeningAnswer(
            questionText: 'Available to start?',
            answerText: 'Immediately',
          ),
        ],
        internalNotes: '',
        appliedAt: now,
        updatedAt: now,
      );
    });

    test('should create from map', () {
      final map = {
        'application_id': 'app2',
        'job_id': 'job2',
        'job_title': 'Backend Developer',
        'recruiter_id': 'recruiter2',
        'seeker_id': 'seeker2',
        'seeker_name': 'Bob Smith',
        'seeker_avatar': '',
        'seeker_headline': 'Full Stack',
        'resume_url': '',
        'status': 'shortlisted',
        'screening_answers': [
          {'question_text': 'Languages?', 'answer_text': 'Python, Go'},
        ],
        'internal_notes': 'Strong candidate',
        'applied_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      };

      final app = ApplicationModel.fromMap(map);

      expect(app.applicationId, 'app2');
      expect(app.jobTitle, 'Backend Developer');
      expect(app.seekerName, 'Bob Smith');
      expect(app.status, 'shortlisted');
      expect(app.screeningAnswers.length, 1);
      expect(app.screeningAnswers.first.answerText, 'Python, Go');
      expect(app.internalNotes, 'Strong candidate');
    });

    test('should convert to map', () {
      final map = application.toMap();

      expect(map['application_id'], 'app1');
      expect(map['job_id'], 'job1');
      expect(map['job_title'], 'Flutter Developer');
      expect(map['seeker_name'], 'Alice Johnson');
      expect(map['status'], 'applied');
      expect(map['screening_answers'], isA<List>());
      expect(map['screening_answers'].length, 2);
      expect(map['applied_at'], isA<Timestamp>());
    });

    test('copyWith should update only specified fields', () {
      final updated = application.copyWith(
        status: 'hired',
        internalNotes: 'Great interview performance',
      );

      expect(updated.status, 'hired');
      expect(updated.internalNotes, 'Great interview performance');
      // Unchanged
      expect(updated.applicationId, 'app1');
      expect(updated.seekerName, 'Alice Johnson');
      expect(updated.jobTitle, 'Flutter Developer');
    });

    test('should handle missing fields with defaults', () {
      final map = <String, dynamic>{
        'application_id': 'a1',
        'job_id': 'j1',
        'job_title': 'Dev',
        'recruiter_id': 'r1',
        'seeker_id': 's1',
        'seeker_name': 'Test',
      };

      final app = ApplicationModel.fromMap(map);

      expect(app.seekerAvatar, '');
      expect(app.seekerHeadline, '');
      expect(app.resumeUrl, '');
      expect(app.status, 'applied');
      expect(app.screeningAnswers, isEmpty);
      expect(app.internalNotes, '');
    });
  });

  group('ScreeningAnswer', () {
    test('should serialize and deserialize', () {
      final answer = ScreeningAnswer(
        questionText: 'Why do you want this role?',
        answerText: 'Passion for Flutter development',
      );

      final map = answer.toMap();
      final restored = ScreeningAnswer.fromMap(map);

      expect(restored.questionText, 'Why do you want this role?');
      expect(restored.answerText, 'Passion for Flutter development');
    });

    test('should handle empty fields', () {
      final answer = ScreeningAnswer.fromMap({});
      expect(answer.questionText, '');
      expect(answer.answerText, '');
    });
  });
}
