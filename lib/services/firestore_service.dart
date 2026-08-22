import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apex_hires/models/job_model.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/models/chat_model.dart';
import 'package:apex_hires/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== JOBS ====================

  Future<String> createJob(JobModel job) async {
    final docRef = _firestore.collection('jobs').doc();
    final newJob = JobModel(
      jobId: docRef.id,
      recruiterId: job.recruiterId,
      companyName: job.companyName,
      companyLogoUrl: job.companyLogoUrl,
      title: job.title,
      description: job.description,
      location: job.location,
      jobType: job.jobType,
      experienceLevel: job.experienceLevel,
      salaryRange: job.salaryRange,
      skillsRequired: job.skillsRequired,
      screeningQuestions: job.screeningQuestions,
      status: 'active',
      applicationsCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newJob.toMap());
    return docRef.id;
  }

  Future<void> updateJob(JobModel job) async {
    await _firestore
        .collection('jobs')
        .doc(job.jobId)
        .update(job.copyWith().toMap());
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _firestore.collection('jobs').doc(jobId).update({
      'status': status,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<JobModel>> getActiveJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'active')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<JobModel>> searchJobs({
    String? query,
    String? location,
    String? jobType,
    String? experienceLevel,
  }) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'active');

    // Note: Firestore query limitations - can't do full-text search natively
    // In production, use Algolia or Typesense for full search
    // For now, filter client-side after fetching

    return q.orderBy('created_at', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data()))
            .where((job) {
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        return job.title.toLowerCase().contains(lowerQuery) ||
            job.companyName.toLowerCase().contains(lowerQuery) ||
            job.description.toLowerCase().contains(lowerQuery);
      }
      return true;
    }).where((job) {
      if (location != null && location.isNotEmpty) {
        return job.location
            .toLowerCase()
            .contains(location.toLowerCase());
      }
      return true;
    }).where((job) {
      if (jobType != null && jobType.isNotEmpty) {
        return job.jobType == jobType;
      }
      return true;
    }).where((job) {
      if (experienceLevel != null && experienceLevel.isNotEmpty) {
        return job.experienceLevel == experienceLevel;
      }
      return true;
    }).toList());
  }

  Future<JobModel?> getJobById(String jobId) async {
    final doc = await _firestore.collection('jobs').doc(jobId).get();
    if (!doc.exists) return null;
    return JobModel.fromMap(doc.data()!);
  }

  Stream<List<JobModel>> getJobsByRecruiter(String recruiterId) {
    return _firestore
        .collection('jobs')
        .where('recruiter_id', isEqualTo: recruiterId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data()))
            .toList());
  }

  // ==================== APPLICATIONS ====================

  Future<String> createApplication(ApplicationModel application) async {
    final docRef = _firestore.collection('applications').doc();
    final newApp = ApplicationModel(
      applicationId: docRef.id,
      jobId: application.jobId,
      jobTitle: application.jobTitle,
      recruiterId: application.recruiterId,
      seekerId: application.seekerId,
      seekerName: application.seekerName,
      seekerAvatar: application.seekerAvatar,
      seekerHeadline: application.seekerHeadline,
      resumeUrl: application.resumeUrl,
      status: 'applied',
      screeningAnswers: application.screeningAnswers,
      appliedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRead: false,
    );
    await docRef.set(newApp.toMap());

    // Increment applications count on the job
    await _firestore.collection('jobs').doc(application.jobId).update({
      'applications_count': FieldValue.increment(1),
    });

    return docRef.id;
  }

  Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    await _firestore.collection('applications').doc(applicationId).update({
      'status': status,
      'is_read': false, // Mark as unread when status changes
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateApplicationNotes(
      String applicationId, String notes) async {
    await _firestore.collection('applications').doc(applicationId).update({
      'internal_notes': notes,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> markApplicationAsRead(String applicationId) async {
    await _firestore.collection('applications').doc(applicationId).update({
      'is_read': true,
    });
  }

  Stream<List<ApplicationModel>> getApplicationsBySeeker(String seekerId) {
    return _firestore
        .collection('applications')
        .where('seeker_id', isEqualTo: seekerId)
        .orderBy('applied_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApplicationModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<ApplicationModel>> getApplicationsByJob(String jobId) {
    return _firestore
        .collection('applications')
        .where('job_id', isEqualTo: jobId)
        .orderBy('applied_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApplicationModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<ApplicationModel>> getApplicationsByRecruiter(
      String recruiterId) {
    return _firestore
        .collection('applications')
        .where('recruiter_id', isEqualTo: recruiterId)
        .orderBy('applied_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ApplicationModel.fromMap(doc.data()))
            .toList());
  }

  Future<bool> hasAlreadyApplied(String jobId, String seekerId) async {
    final result = await _firestore
        .collection('applications')
        .where('job_id', isEqualTo: jobId)
        .where('seeker_id', isEqualTo: seekerId)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<ApplicationModel?> getApplicationById(String applicationId) async {
    final doc = await _firestore.collection('applications').doc(applicationId).get();
    if (!doc.exists) return null;
    return ApplicationModel.fromMap(doc.data()!);
  }

  // ==================== CHATS ====================

  Future<String> getOrCreateChat({
    required String applicationId,
    required String jobId,
    required String seekerId,
    required String recruiterId,
  }) async {
    // Check if chat already exists for this application
    final existing = await _firestore
        .collection('chats')
        .where('application_id', isEqualTo: applicationId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final docRef = _firestore.collection('chats').doc();
    final chat = ChatModel(
      chatId: docRef.id,
      applicationId: applicationId,
      jobId: jobId,
      participants: [seekerId, recruiterId],
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      unreadCount: {seekerId: 0, recruiterId: 0},
    );
    await docRef.set(chat.toMap());
    return docRef.id;
  }

  Stream<List<ChatModel>> getChatsForUser(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final docRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      messageId: docRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await docRef.set(message.toMap());

    // Update chat last message
    await _firestore.collection('chats').doc(chatId).update({
      'last_message': text,
      'last_message_time': Timestamp.fromDate(DateTime.now()),
      'unread_count.$receiverId': FieldValue.increment(1),
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final unread = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiver_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();

    await _firestore.collection('chats').doc(chatId).update({
      'unread_count.$userId': 0,
    });
  }

  // ==================== USERS ====================

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // ==================== ADMIN ====================

  Stream<int> getActiveUsersCount() {
    return _firestore.collection('users').snapshots().map(
        (snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalJobsCount() {
    return _firestore
        .collection('jobs')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalApplicationsCount() {
    return _firestore
        .collection('applications')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getActiveChatsCount() {
    return _firestore
        .collection('chats')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<QueryDocumentSnapshot>> getRecentUsers({int limit = 5}) {
    return _firestore
        .collection('users')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot>> getRecentJobs({int limit = 5}) {
    return _firestore
        .collection('jobs')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot>> getRecentApplications({int limit = 5}) {
    return _firestore
        .collection('applications')
        .orderBy('applied_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // ==================== CHART DATA ====================

  /// Returns application status breakdown as a map of status -> count.
  Stream<Map<String, int>> getApplicationStatusCounts() {
    return _firestore.collection('applications').snapshots().map((snapshot) {
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'unknown';
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Returns user role breakdown as a map of role -> count.
  Stream<Map<String, int>> getUserRoleCounts() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final role = doc.data()['role'] as String? ?? 'unknown';
        counts[role] = (counts[role] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Returns job status breakdown as a map of status -> count.
  Stream<Map<String, int>> getJobStatusCounts() {
    return _firestore.collection('jobs').snapshots().map((snapshot) {
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'unknown';
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Returns applications count grouped by day for the last 7 days.
  Stream<List<MapEntry<String, int>>> getApplicationTrend() {
    return _firestore.collection('applications').snapshots().map((snapshot) {
      final now = DateTime.now();
      final dailyCounts = <String, int>{};

      // Initialize last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = '${date.month}/${date.day}';
        dailyCounts[key] = 0;
      }

      // Count applications per day
      for (final doc in snapshot.docs) {
        final appliedAt = (doc.data()['applied_at'] as Timestamp?)?.toDate();
        if (appliedAt == null) continue;
        final diff = now.difference(appliedAt).inDays;
        if (diff < 7) {
          final key = '${appliedAt.month}/${appliedAt.day}';
          dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
        }
      }

      return dailyCounts.entries.toList();
    });
  }

  Future<void> verifyRecruiter(String uid, bool isVerified) async {
    await _firestore.collection('users').doc(uid).update({
      'recruiter_profile.is_verified': isVerified,
    });
  }

  Future<void> blockUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'is_blocked': true,
    });
  }

  Future<void> createAdminAccount({
    required String uid,
    required String email,
    required String fullName,
  }) async {
    final userModel = UserModel(
      uid: uid,
      email: email,
      role: 'admin',
      fullName: fullName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(uid).set(userModel.toMap());
  }

  Future<void> removeJob(String jobId) async {
    await _firestore.collection('jobs').doc(jobId).delete();
  }
}
