import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:apex_hires/services/firestore_service.dart';
import 'package:apex_hires/services/notification_service.dart';

class AdminProvider extends ChangeNotifier {
  FirestoreService? _firestoreServiceRef;
  FirestoreService get _firestoreService =>
      _firestoreServiceRef ??= FirestoreService();

  final bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Metric streams
  Stream<int> get totalUsers => _firestoreService.getActiveUsersCount();
  Stream<int> get totalJobs => _firestoreService.getTotalJobsCount();
  Stream<int> get totalApplications => _firestoreService.getTotalApplicationsCount();
  Stream<int> get totalActiveChats => _firestoreService.getActiveChatsCount();

  // Recent activity streams
  Stream<List<QueryDocumentSnapshot>> getRecentUsers({int limit = 5}) => _firestoreService.getRecentUsers(limit: limit);
  Stream<List<QueryDocumentSnapshot>> getRecentJobs({int limit = 5}) => _firestoreService.getRecentJobs(limit: limit);
  Stream<List<QueryDocumentSnapshot>> getRecentApplications({int limit = 5}) => _firestoreService.getRecentApplications(limit: limit);

  // Chart data streams
  Stream<Map<String, int>> get applicationStatusCounts => _firestoreService.getApplicationStatusCounts();
  Stream<Map<String, int>> get userRoleCounts => _firestoreService.getUserRoleCounts();
  Stream<Map<String, int>> get jobStatusCounts => _firestoreService.getJobStatusCounts();
  Stream<List<MapEntry<String, int>>> get applicationTrend => _firestoreService.getApplicationTrend();

  // User management
  Future<void> verifyRecruiter(String uid) async {
    try {
      await _firestoreService.verifyRecruiter(uid, true);
      await _sendToUser(
        targetUserId: uid,
        title: '✅ Account Verified!',
        body: 'Your recruiter account has been verified. You can now post jobs.',
        type: 'recruiter_verified',
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> unverifyRecruiter(String uid) async {
    try {
      await _firestoreService.verifyRecruiter(uid, false);
      await _sendToUser(
        targetUserId: uid,
        title: '⚠️ Verification Removed',
        body: 'Your recruiter verification has been removed. Job posting is now restricted.',
        type: 'recruiter_unverified',
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> blockUser(String uid) async {
    try {
      await _firestoreService.blockUser(uid);
      await _sendToUser(
        targetUserId: uid,
        title: '🚫 Account Blocked',
        body: 'Your account has been blocked by an administrator. Please contact support.',
        type: 'user_blocked',
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> unblockUser(String uid) async {
    try {
      await _firestoreService.unblockUser(uid);
      await _sendToUser(
        targetUserId: uid,
        title: '✅ Account Unblocked',
        body: 'Your account has been unblocked. You can now sign in.',
        type: 'user_unblocked',
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> recoverDeletedUser(String uid) async {
    try {
      await _firestoreService.recoverDeletedUser(uid);
      await _sendToUser(
        targetUserId: uid,
        title: '♻️ Account Recovered',
        body: 'Your account has been recovered by an administrator. You can now sign in.',
        type: 'user_recovered',
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Admin management
  Future<bool> createAdminAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create user via Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(fullName);

      // Save admin profile to Firestore
      await _firestoreService.createAdminAccount(
        uid: uid,
        email: email,
        fullName: fullName,
      );

      return true;
    } catch (e) {
      _setError(_parseAdminError(e.toString()));
      return false;
    }
  }

  String _parseAdminError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (error.contains('invalid-email')) return 'Invalid email address.';
    if (error.contains('weak-password')) return 'Password is too weak.';
    return 'Failed to create admin account. Please try again.';
  }

  // Job moderation
  Future<void> removeJob(String jobId) async {
    try {
      // Look up the job to get the recruiter ID before deleting
      final job = await _firestoreService.getJobById(jobId);
      await _firestoreService.removeJob(jobId);
      if (job != null) {
        await _sendToUser(
          targetUserId: job.recruiterId,
          title: '🗑️ Job Removed',
          body: 'Your job listing "${job.title}" has been removed by an admin.',
          type: 'job_removed',
          data: {'job_id': jobId, 'job_title': job.title},
        );
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> pauseJob(String jobId) async {
    try {
      final job = await _firestoreService.getJobById(jobId);
      if (job == null) return;

      final newStatus = job.status == 'paused' ? 'active' : 'paused';
      await _firestoreService.updateJobStatus(jobId, newStatus);

      if (newStatus == 'paused') {
        await _sendToUser(
          targetUserId: job.recruiterId,
          title: '⏸️ Job Paused',
          body: 'Your job listing "${job.title}" has been paused by an admin.',
          type: 'job_paused',
          data: {'job_id': jobId, 'job_title': job.title},
        );
      } else {
        await _sendToUser(
          targetUserId: job.recruiterId,
          title: '▶️ Job Reactivated',
          body: 'Your job listing "${job.title}" has been reactivated by an admin.',
          type: 'job_reactivated',
          data: {'job_id': jobId, 'job_title': job.title},
        );
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Send notification to a target user (fire-and-forget)
  Future<void> _sendToUser({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await NotificationService().sendNotification(
        targetUserId: targetUserId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
    } catch (e) {
      // Don't fail the admin action if notification fails
      debugPrint('⚠️ Failed to send notification: $e');
    }
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
