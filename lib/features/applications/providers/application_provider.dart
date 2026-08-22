import 'package:flutter/material.dart';
import 'package:apex_hires/models/application_model.dart';
import 'package:apex_hires/services/firestore_service.dart';
import 'package:apex_hires/services/notification_service.dart';

class ApplicationProvider extends ChangeNotifier {
  FirestoreService? _firestoreServiceRef;
  FirestoreService get _firestoreService =>
      _firestoreServiceRef ??= FirestoreService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get applications by seeker
  Stream<List<ApplicationModel>> getApplicationsBySeeker(String seekerId) {
    return _firestoreService.getApplicationsBySeeker(seekerId);
  }

  // Get applications by recruiter
  Stream<List<ApplicationModel>> getApplicationsByRecruiter(String recruiterId) {
    return _firestoreService.getApplicationsByRecruiter(recruiterId);
  }

  // Get applications for a specific job
  Stream<List<ApplicationModel>> getApplicationsByJob(String jobId) {
    return _firestoreService.getApplicationsByJob(jobId);
  }

  // Check if already applied
  Future<bool> hasAlreadyApplied(String jobId, String seekerId) async {
    return _firestoreService.hasAlreadyApplied(jobId, seekerId);
  }

  // Submit application
  Future<String?> submitApplication(ApplicationModel application) async {
    _setLoading(true);
    try {
      final id = await _firestoreService.createApplication(application);

      // Notify the recruiter about the new application
      await NotificationService().sendNotification(
        targetUserId: application.recruiterId,
        title: '📩 New Application',
        body: '${application.seekerName} applied for "${application.jobTitle}"',
        type: 'new_application',
        data: {
          'application_id': id,
          'job_id': application.jobId,
          'seeker_id': application.seekerId,
        },
      );

      _setLoading(false);
      return id;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Update status (recruiter)
  Future<bool> updateStatus(String applicationId, String status) async {
    try {
      await _firestoreService.updateApplicationStatus(applicationId, status);

      // Look up the application to get seeker info for notification
      final appSnapshot = await _firestoreService.getApplicationById(applicationId);
      if (appSnapshot != null) {
        final notificationTitle = _statusNotificationTitle(status);
        final notificationBody = _statusNotificationBody(status, appSnapshot.jobTitle);

        await NotificationService().sendNotification(
          targetUserId: appSnapshot.seekerId,
          title: notificationTitle,
          body: notificationBody,
          type: 'application_status_changed',
          data: {
            'application_id': applicationId,
            'job_id': appSnapshot.jobId,
            'status': status,
          },
        );
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  String _statusNotificationTitle(String status) {
    switch (status) {
      case 'shortlisted':
        return '⭐ Shortlisted!';
      case 'interviewing':
        return '🎤 Interview Invitation';
      case 'hired':
        return '🎉 Congratulations!';
      case 'rejected':
        return 'Application Update';
      default:
        return '📋 Application Update';
    }
  }

  String _statusNotificationBody(String status, String jobTitle) {
    switch (status) {
      case 'shortlisted':
        return 'You\'ve been shortlisted for "$jobTitle". The recruiter will be in touch soon!';
      case 'interviewing':
        return 'You\'ve been invited to interview for "$jobTitle". Check your messages for details.';
      case 'hired':
        return 'Congratulations! You\'ve been hired for "$jobTitle"! 🎉';
      case 'rejected':
        return 'Unfortunately, your application for "$jobTitle" was not selected. Keep applying!';
      default:
        return 'Your application status for "$jobTitle" has been updated.';
    }
  }

  // Update notes (recruiter)
  Future<bool> updateNotes(String applicationId, String notes) async {
    try {
      await _firestoreService.updateApplicationNotes(applicationId, notes);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Mark application as read
  Future<void> markAsRead(String applicationId) async {
    try {
      await _firestoreService.markApplicationAsRead(applicationId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
