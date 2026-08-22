import 'dart:io';
import 'package:flutter/foundation.dart';

/// StorageService handles file uploads to Firebase Storage.
///
/// On the Firebase Spark (free) plan, Storage is not available.
/// When Storage is unavailable, all upload methods return empty strings
/// and the app continues to work without file uploads.
///
/// To enable Storage, upgrade to Firebase Blaze plan.
class StorageService {
  bool? _available;

  /// Whether Firebase Storage is available.
  /// Lazily checked on first use.
  bool get isAvailable {
    _available ??= _checkAvailability();
    return _available!;
  }

  bool _checkAvailability() {
    // On the Firebase Spark (free) plan, Storage is not included.
    // To enable file uploads, upgrade to Blaze plan and uncomment
    // the FirebaseStorage import and check below.
    debugPrint(
      'Firebase Storage: File uploads disabled (Spark plan). '
      'Upgrade to Blaze plan to enable avatars, resumes, and logos.',
    );
    return false;
  }

  /// Enable storage availability (call after confirming Storage is set up).
  void enableStorage() {
    _available = true;
  }

  /// Upload avatar image. Returns empty string if Storage is unavailable.
  Future<String> uploadAvatar(String userId, File imageFile) async {
    if (!isAvailable) {
      debugPrint('Skipping avatar upload — Firebase Storage not available');
      return '';
    }
    try {
      // Storage upload logic would go here when Blaze plan is active
      return '';
    } catch (e) {
      debugPrint('Avatar upload failed: $e');
      return '';
    }
  }

  /// Upload resume PDF. Returns empty map if Storage is unavailable.
  Future<Map<String, String>> uploadResume(
      String userId, File resumeFile, String fileName) async {
    if (!isAvailable) {
      debugPrint('Skipping resume upload — Firebase Storage not available');
      return {'url': '', 'name': ''};
    }
    try {
      return {'url': '', 'name': ''};
    } catch (e) {
      debugPrint('Resume upload failed: $e');
      return {'url': '', 'name': ''};
    }
  }

  /// Upload company logo. Returns empty string if Storage is unavailable.
  Future<String> uploadCompanyLogo(String userId, File logoFile) async {
    if (!isAvailable) {
      debugPrint('Skipping logo upload — Firebase Storage not available');
      return '';
    }
    try {
      return '';
    } catch (e) {
      debugPrint('Logo upload failed: $e');
      return '';
    }
  }

  /// Delete file from Storage. No-op if Storage is unavailable.
  Future<void> deleteFile(String url) async {
    if (!isAvailable || url.isEmpty) return;
    try {
      // Delete logic would go here
    } catch (e) {
      // Ignore
    }
  }
}
