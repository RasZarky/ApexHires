import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

/// Tests for Firestore data layer operations using FakeFirebaseFirestore.
/// These tests verify the data model behavior against a real Firestore-like
/// database without requiring Firebase initialization.
void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Jobs Collection', () {
    test('should store and retrieve a job', () async {
      await fakeFirestore.collection('jobs').doc('j1').set({
        'job_id': 'j1',
        'recruiter_id': 'recruiter1',
        'company_name': 'TechCorp',
        'title': 'Flutter Developer',
        'description': 'Build mobile apps',
        'location': 'Remote',
        'job_type': 'Remote',
        'experience_level': 'Mid',
        'salary_range': {'min': 80000, 'max': 120000, 'currency': 'USD'},
        'skills_required': ['Flutter', 'Dart'],
        'screening_questions': [],
        'status': 'active',
        'applications_count': 0,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      });

      final doc = await fakeFirestore.collection('jobs').doc('j1').get();
      expect(doc.exists, true);
      expect(doc.data()!['title'], 'Flutter Developer');
      expect(doc.data()!['job_type'], 'Remote');
    });

    test('should filter active jobs only', () async {
      await fakeFirestore.collection('jobs').doc('j1').set({
        'title': 'Active Job',
        'status': 'active',
      });
      await fakeFirestore.collection('jobs').doc('j2').set({
        'title': 'Paused Job',
        'status': 'paused',
      });

      final activeJobs = await fakeFirestore
          .collection('jobs')
          .where('status', isEqualTo: 'active')
          .get();

      expect(activeJobs.docs.length, 1);
      expect(activeJobs.docs.first.data()['title'], 'Active Job');
    });

    test('should filter jobs by recruiter', () async {
      await fakeFirestore.collection('jobs').doc('j1').set({
        'recruiter_id': 'r1',
        'title': 'Job 1',
      });
      await fakeFirestore.collection('jobs').doc('j2').set({
        'recruiter_id': 'r2',
        'title': 'Job 2',
      });

      final r1Jobs = await fakeFirestore
          .collection('jobs')
          .where('recruiter_id', isEqualTo: 'r1')
          .get();

      expect(r1Jobs.docs.length, 1);
      expect(r1Jobs.docs.first.data()['title'], 'Job 1');
    });

    test('should update job status', () async {
      await fakeFirestore.collection('jobs').doc('j1').set({
        'status': 'active',
      });

      await fakeFirestore.collection('jobs').doc('j1').update({
        'status': 'paused',
      });

      final doc = await fakeFirestore.collection('jobs').doc('j1').get();
      expect(doc.data()!['status'], 'paused');
    });

    test('should delete a job', () async {
      await fakeFirestore.collection('jobs').doc('j1').set({'title': 'Test'});
      await fakeFirestore.collection('jobs').doc('j1').delete();

      final doc = await fakeFirestore.collection('jobs').doc('j1').get();
      expect(doc.exists, false);
    });

    test('should increment applications count', () async {
      await fakeFirestore.collection('jobs').doc('j1').set({
        'applications_count': 0,
      });

      await fakeFirestore.collection('jobs').doc('j1').update({
        'applications_count': 1,
      });

      final doc = await fakeFirestore.collection('jobs').doc('j1').get();
      expect(doc.data()!['applications_count'], 1);
    });
  });

  group('Applications Collection', () {
    test('should store and retrieve an application', () async {
      await fakeFirestore.collection('applications').doc('a1').set({
        'application_id': 'a1',
        'job_id': 'j1',
        'job_title': 'Flutter Dev',
        'recruiter_id': 'r1',
        'seeker_id': 's1',
        'seeker_name': 'Alice Johnson',
        'status': 'applied',
        'screening_answers': [
          {'question_text': 'Years of exp?', 'answer_text': '5'},
        ],
        'applied_at': DateTime.now(),
        'updated_at': DateTime.now(),
      });

      final doc = await fakeFirestore.collection('applications').doc('a1').get();
      expect(doc.exists, true);
      expect(doc.data()!['seeker_name'], 'Alice Johnson');
      expect(doc.data()!['status'], 'applied');
    });

    test('should filter applications by seeker', () async {
      await fakeFirestore.collection('applications').doc('a1').set({
        'seeker_id': 's1',
        'job_title': 'Job 1',
      });
      await fakeFirestore.collection('applications').doc('a2').set({
        'seeker_id': 's2',
        'job_title': 'Job 1',
      });

      final s1Apps = await fakeFirestore
          .collection('applications')
          .where('seeker_id', isEqualTo: 's1')
          .get();

      expect(s1Apps.docs.length, 1);
    });

    test('should filter applications by job', () async {
      await fakeFirestore.collection('applications').doc('a1').set({
        'job_id': 'j1',
        'seeker_name': 'Alice',
      });
      await fakeFirestore.collection('applications').doc('a2').set({
        'job_id': 'j1',
        'seeker_name': 'Bob',
      });
      await fakeFirestore.collection('applications').doc('a3').set({
        'job_id': 'j2',
        'seeker_name': 'Charlie',
      });

      final j1Apps = await fakeFirestore
          .collection('applications')
          .where('job_id', isEqualTo: 'j1')
          .get();

      expect(j1Apps.docs.length, 2);
    });

    test('should filter applications by recruiter', () async {
      await fakeFirestore.collection('applications').doc('a1').set({
        'recruiter_id': 'r1',
      });
      await fakeFirestore.collection('applications').doc('a2').set({
        'recruiter_id': 'r2',
      });

      final r1Apps = await fakeFirestore
          .collection('applications')
          .where('recruiter_id', isEqualTo: 'r1')
          .get();

      expect(r1Apps.docs.length, 1);
    });

    test('should update application status', () async {
      await fakeFirestore.collection('applications').doc('a1').set({
        'status': 'applied',
      });

      await fakeFirestore.collection('applications').doc('a1').update({
        'status': 'shortlisted',
      });

      final doc = await fakeFirestore.collection('applications').doc('a1').get();
      expect(doc.data()!['status'], 'shortlisted');
    });

    test('should update internal notes', () async {
      await fakeFirestore.collection('applications').doc('a1').set({
        'internal_notes': '',
      });

      await fakeFirestore.collection('applications').doc('a1').update({
        'internal_notes': 'Strong candidate, great portfolio',
      });

      final doc = await fakeFirestore.collection('applications').doc('a1').get();
      expect(doc.data()!['internal_notes'], 'Strong candidate, great portfolio');
    });

    test('should check if seeker already applied', () async {
      await fakeFirestore.collection('applications').doc('a1').set({
        'job_id': 'j1',
        'seeker_id': 's1',
      });

      final existing = await fakeFirestore
          .collection('applications')
          .where('job_id', isEqualTo: 'j1')
          .where('seeker_id', isEqualTo: 's1')
          .limit(1)
          .get();

      expect(existing.docs.isNotEmpty, true);

      final notExisting = await fakeFirestore
          .collection('applications')
          .where('job_id', isEqualTo: 'j1')
          .where('seeker_id', isEqualTo: 's999')
          .limit(1)
          .get();

      expect(notExisting.docs.isEmpty, true);
    });
  });

  group('Chats Collection', () {
    test('should create chat and messages', () async {
      final chatRef = fakeFirestore.collection('chats').doc();
      await chatRef.set({
        'chat_id': chatRef.id,
        'application_id': 'a1',
        'job_id': 'j1',
        'participants': ['s1', 'r1'],
        'last_message': '',
        'last_message_time': DateTime.now(),
        'unread_count': {'s1': 0, 'r1': 0},
      });

      // Add messages
      final msgRef = chatRef.collection('messages').doc();
      await msgRef.set({
        'message_id': msgRef.id,
        'sender_id': 's1',
        'receiver_id': 'r1',
        'text': 'Hello!',
        'is_read': false,
        'created_at': DateTime.now(),
      });

      // Update chat
      await chatRef.update({
        'last_message': 'Hello!',
        'last_message_time': DateTime.now(),
        'unread_count': {'s1': 0, 'r1': 1},
      });

      final chatDoc = await fakeFirestore.collection('chats').doc(chatRef.id).get();
      expect(chatDoc.data()!['last_message'], 'Hello!');

      final messages = await chatRef.collection('messages').get();
      expect(messages.docs.length, 1);
      expect(messages.docs.first.data()['text'], 'Hello!');
    });

    test('should filter chats by participant', () async {
      await fakeFirestore.collection('chats').doc('c1').set({
        'participants': ['s1', 'r1'],
        'last_message_time': DateTime.now(),
      });
      await fakeFirestore.collection('chats').doc('c2').set({
        'participants': ['s2', 'r2'],
        'last_message_time': DateTime.now(),
      });

      final s1Chats = await fakeFirestore
          .collection('chats')
          .where('participants', arrayContains: 's1')
          .get();

      expect(s1Chats.docs.length, 1);
      expect(s1Chats.docs.first.id, 'c1');
    });

    test('should update unread counts', () async {
      await fakeFirestore.collection('chats').doc('c1').set({
        'unread_count': {'s1': 0, 'r1': 0},
      });

      await fakeFirestore.collection('chats').doc('c1').update({
        'unread_count.r1': 1,
      });

      final doc = await fakeFirestore.collection('chats').doc('c1').get();
      expect(doc.data()!['unread_count']['r1'], 1);
    });

    test('should mark messages as read', () async {
      final chatRef = fakeFirestore.collection('chats').doc('c1');
      await chatRef.collection('messages').doc('m1').set({
        'is_read': false,
        'receiver_id': 'r1',
      });
      await chatRef.collection('messages').doc('m2').set({
        'is_read': true,
        'receiver_id': 'r1',
      });

      final unread = await chatRef
          .collection('messages')
          .where('receiver_id', isEqualTo: 'r1')
          .where('is_read', isEqualTo: false)
          .get();

      expect(unread.docs.length, 1);

      // Mark as read
      for (final doc in unread.docs) {
        await doc.reference.update({'is_read': true});
      }

      final afterMark = await chatRef
          .collection('messages')
          .where('is_read', isEqualTo: false)
          .get();

      expect(afterMark.docs.length, 0);
    });
  });

  group('Users Collection', () {
    test('should store and retrieve user profile', () async {
      await fakeFirestore.collection('users').doc('u1').set({
        'uid': 'u1',
        'email': 'test@test.com',
        'role': 'job_seeker',
        'full_name': 'Test User',
        'seeker_profile': {
          'headline': 'Developer',
          'skills': ['Flutter', 'Dart'],
        },
      });

      final doc = await fakeFirestore.collection('users').doc('u1').get();
      expect(doc.data()!['full_name'], 'Test User');
      expect(doc.data()!['seeker_profile']['headline'], 'Developer');
      expect(doc.data()!['seeker_profile']['skills'], ['Flutter', 'Dart']);
    });

    test('should update user profile', () async {
      await fakeFirestore.collection('users').doc('u1').set({
        'full_name': 'Original',
        'role': 'job_seeker',
      });

      await fakeFirestore.collection('users').doc('u1').update({
        'full_name': 'Updated Name',
      });

      final doc = await fakeFirestore.collection('users').doc('u1').get();
      expect(doc.data()!['full_name'], 'Updated Name');
    });

    test('should update recruiter verification status', () async {
      await fakeFirestore.collection('users').doc('u1').set({
        'role': 'recruiter',
        'recruiter_profile': {
          'is_verified': false,
          'company_name': 'Acme',
        },
      });

      await fakeFirestore.collection('users').doc('u1').update({
        'recruiter_profile.is_verified': true,
      });

      final doc = await fakeFirestore.collection('users').doc('u1').get();
      expect(doc.data()!['recruiter_profile']['is_verified'], true);
    });

    test('should block a user', () async {
      await fakeFirestore.collection('users').doc('u1').set({
        'full_name': 'Bad User',
      });

      await fakeFirestore.collection('users').doc('u1').update({
        'is_blocked': true,
      });

      final doc = await fakeFirestore.collection('users').doc('u1').get();
      expect(doc.data()!['is_blocked'], true);
    });
  });

  group('FieldValue operations', () {
    test('FieldValue.increment should work for application count', () async {
      await fakeFirestore.collection('jobs').doc('j1').set({
        'applications_count': 5,
      });

      await fakeFirestore.collection('jobs').doc('j1').update({
        'applications_count': FieldValue.increment(1),
      });

      final doc = await fakeFirestore.collection('jobs').doc('j1').get();
      expect(doc.data()!['applications_count'], 6);
    });
  });
}
