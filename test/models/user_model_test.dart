import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apex_hires/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel from map', () {
      final now = DateTime.now();
      final map = {
        'uid': 'user123',
        'email': 'test@example.com',
        'role': 'job_seeker',
        'full_name': 'John Doe',
        'phone_number': '+1234567890',
        'avatar_url': 'https://example.com/avatar.jpg',
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
        'seeker_profile': {
          'headline': 'Flutter Developer',
          'bio': 'Passionate about mobile development',
          'location': 'San Francisco, CA',
          'resume_url': 'https://example.com/resume.pdf',
          'resume_name': 'resume.pdf',
          'skills': ['Flutter', 'Dart', 'Firebase'],
          'experience': [
            {
              'title': 'Senior Developer',
              'company': 'TechCorp',
              'start_date': '2020-01',
              'end_date': '',
              'description': 'Built apps',
              'is_current': true,
            }
          ],
          'education': [
            {
              'degree': 'BS Computer Science',
              'institution': 'MIT',
              'start_year': '2016',
              'end_year': '2020',
            }
          ],
        },
        'recruiter_profile': null,
      };

      final user = UserModel.fromMap(map);

      expect(user.uid, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.role, 'job_seeker');
      expect(user.fullName, 'John Doe');
      expect(user.phoneNumber, '+1234567890');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.seekerProfile, isNotNull);
      expect(user.seekerProfile!.headline, 'Flutter Developer');
      expect(user.seekerProfile!.skills, ['Flutter', 'Dart', 'Firebase']);
      expect(user.seekerProfile!.experience.length, 1);
      expect(user.seekerProfile!.experience.first.title, 'Senior Developer');
      expect(user.seekerProfile!.experience.first.isCurrent, true);
      expect(user.seekerProfile!.education.length, 1);
      expect(user.seekerProfile!.education.first.degree, 'BS Computer Science');
      expect(user.recruiterProfile, isNull);
    });

    test('should convert UserModel to map', () {
      final user = UserModel(
        uid: 'user456',
        email: 'jane@test.com',
        role: 'recruiter',
        fullName: 'Jane Smith',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 6, 1),
        recruiterProfile: RecruiterProfile(
          companyName: 'Acme Inc',
          designation: 'HR Manager',
        ),
      );

      final map = user.toMap();

      expect(map['uid'], 'user456');
      expect(map['email'], 'jane@test.com');
      expect(map['role'], 'recruiter');
      expect(map['full_name'], 'Jane Smith');
      expect(map['created_at'], isA<Timestamp>());
      expect(map['recruiter_profile'], isNotNull);
      expect(map['recruiter_profile']['company_name'], 'Acme Inc');
    });

    test('copyWith should update only specified fields', () {
      final user = UserModel(
        uid: 'u1',
        email: 'a@b.com',
        role: 'job_seeker',
        fullName: 'Original Name',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final updated = user.copyWith(
        fullName: 'New Name',
        phoneNumber: '555-0100',
      );

      expect(updated.fullName, 'New Name');
      expect(updated.phoneNumber, '555-0100');
      expect(updated.email, 'a@b.com'); // unchanged
      expect(updated.uid, 'u1'); // unchanged
      expect(updated.updatedAt.isAfter(user.createdAt), true);
    });

    test('should handle missing fields gracefully with defaults', () {
      final map = <String, dynamic>{
        'uid': 'u1',
        'email': 'a@b.com',
        'role': 'job_seeker',
        'full_name': 'Test',
      };

      final user = UserModel.fromMap(map);

      expect(user.phoneNumber, '');
      expect(user.avatarUrl, '');
      expect(user.seekerProfile, isNull);
      expect(user.recruiterProfile, isNull);
    });
  });

  group('RecruiterProfile', () {
    test('should serialize and deserialize correctly', () {
      final profile = RecruiterProfile(
        companyName: 'TechCo',
        companyWebsite: 'https://techco.com',
        companyLogoUrl: 'https://example.com/logo.png',
        designation: 'CTO',
        isVerified: true,
      );

      final map = profile.toMap();
      final restored = RecruiterProfile.fromMap(map);

      expect(restored.companyName, 'TechCo');
      expect(restored.companyWebsite, 'https://techco.com');
      expect(restored.companyLogoUrl, 'https://example.com/logo.png');
      expect(restored.designation, 'CTO');
      expect(restored.isVerified, true);
    });

    test('copyWith should override specified fields', () {
      final profile = RecruiterProfile(
        companyName: 'OldCo',
        designation: 'Intern',
      );

      final updated = profile.copyWith(
        companyName: 'NewCo',
        isVerified: true,
      );

      expect(updated.companyName, 'NewCo');
      expect(updated.isVerified, true);
      expect(updated.designation, 'Intern'); // unchanged
    });
  });

  group('Experience', () {
    test('should create from map with all fields', () {
      final exp = Experience.fromMap({
        'title': 'Developer',
        'company': 'Google',
        'start_date': '2021-03',
        'end_date': '2023-12',
        'description': 'Built features',
        'is_current': false,
      });

      expect(exp.title, 'Developer');
      expect(exp.company, 'Google');
      expect(exp.startDate, '2021-03');
      expect(exp.endDate, '2023-12');
      expect(exp.description, 'Built features');
      expect(exp.isCurrent, false);
    });

    test('should handle empty map with defaults', () {
      final exp = Experience.fromMap({});
      expect(exp.title, '');
      expect(exp.company, '');
      expect(exp.isCurrent, false);
    });
  });

  group('Education', () {
    test('should serialize and deserialize', () {
      final edu = Education(
        degree: 'MBA',
        institution: 'Harvard',
        startYear: '2018',
        endYear: '2020',
      );

      final map = edu.toMap();
      final restored = Education.fromMap(map);

      expect(restored.degree, 'MBA');
      expect(restored.institution, 'Harvard');
      expect(restored.startYear, '2018');
      expect(restored.endYear, '2020');
    });
  });
}
