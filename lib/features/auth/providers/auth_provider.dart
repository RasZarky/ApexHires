import 'dart:io';
import 'package:flutter/material.dart';
import 'package:apex_hires/models/user_model.dart';
import 'package:apex_hires/services/auth_service.dart';
import 'package:apex_hires/services/supabase_storage_service.dart';
import 'package:apex_hires/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthService? _authService;
  StorageService? _storageService;

  AuthService get _auth => _authService ??= AuthService();
  StorageService get _storage => _storageService ??= StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _developerUnlocked = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get developerUnlocked => _developerUnlocked;

  /// Whether file uploads (avatar, resume, logo) are available.
  bool get isStorageAvailable => _storage.isAvailable;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Initialize: check if user is already signed in
  Future<void> init() async {
    _setLoading(true);
    try {
      _user = await _auth.getCurrentUserModel();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  // Sign up with email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _user = await _auth.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      _setLoading(false);
      return _user != null;
    } catch (e) {
      _setError(_parseAuthError(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _user = await _auth.signInWithEmail(
        email: email,
        password: password,
      );
      _setLoading(false);
      return _user != null;
    } catch (e) {
      _setError(_parseAuthError(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle({required String role}) async {
    _setLoading(true);
    _setError(null);
    try {
      _user = await _auth.signInWithGoogle(role: role);
      _setLoading(false);
      return _user != null;
    } catch (e) {
      _setError(_parseAuthError(e.toString()));
      _setLoading(false);
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    SeekerProfile? seekerProfile,
    RecruiterProfile? recruiterProfile,
    File? avatarFile,
    File? resumeFile,
    String? resumeName,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      if (_user == null) return false;

      String? avatarUrl = _user!.avatarUrl;
      String? resumeUrl = _user!.seekerProfile?.resumeUrl ?? '';
      String finalResumeName =
          resumeName ?? _user!.seekerProfile?.resumeName ?? '';

      // Upload avatar if provided
      if (avatarFile != null) {
        avatarUrl = await _storage.uploadAvatar(
          _user!.uid,
          avatarFile,
        );
        // Only update if upload succeeded
        if (avatarUrl.isEmpty) avatarUrl = _user!.avatarUrl;
      }

      // Upload resume if provided
      if (resumeFile != null) {
        final result = await _storage.uploadResume(
          _user!.uid,
          resumeFile,
          resumeFile.path.split('/').last,
        );
        if (result['url']!.isNotEmpty) {
          resumeUrl = result['url'];
          finalResumeName = result['name']!;
        }
      }

      // Build updated seeker profile
      SeekerProfile? updatedSeekerProfile;
      if (seekerProfile != null) {
        updatedSeekerProfile = SeekerProfile(
          headline: seekerProfile.headline,
          bio: seekerProfile.bio,
          location: seekerProfile.location,
          resumeUrl: resumeUrl ?? '',
          resumeName: finalResumeName,
          skills: seekerProfile.skills,
          experience: seekerProfile.experience,
          education: seekerProfile.education,
        );
      }

      // Build updated recruiter profile
      RecruiterProfile? updatedRecruiterProfile;
      if (recruiterProfile != null) {
        updatedRecruiterProfile = recruiterProfile;
      }

      _user = _user!.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        seekerProfile: updatedSeekerProfile ?? _user!.seekerProfile,
        recruiterProfile: updatedRecruiterProfile ?? _user!.recruiterProfile,
      );

      await _auth.updateUserProfile(_user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Refresh user data from Firestore
  Future<void> refreshUser() async {
    try {
      _user = await _auth.getCurrentUserModel();
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  // Delete account (soft delete with reason)
  Future<bool> deleteAccount({String reason = ''}) async {
    _setLoading(true);
    _setError(null);
    try {
      if (_user == null) return false;
      await _auth.deleteAccount(userId: _user!.uid, reason: reason);
      _user = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Developer mode
  void unlockDeveloperMode() {
    _developerUnlocked = true;
    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await NotificationService().clearUser();
    } catch (e) {
      // OneSignal may not be initialized in tests
    }
    try {
      await _auth.signOut();
    } catch (e) {
      // Firebase may not be initialized in tests
    }
    _user = null;
    notifyListeners();
  }

  String _parseAuthError(String error) {
    if (error.contains('blocked')) {
      return 'Your account has been blocked. Please contact support.';
    }
    if (error.contains('deleted')) {
      return 'Your account has been deleted. Please contact support to recover it.';
    }
    if (error.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (error.contains('wrong-password')) return 'Incorrect password.';
    if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (error.contains('invalid-email')) return 'Invalid email address.';
    if (error.contains('weak-password')) return 'Password is too weak.';
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Try again later.';
    }
    if (error.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    return 'An error occurred. Please try again.';
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setError(null);
    try {
      await _auth.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(_parseAuthError(e.toString()));
      return false;
    }
  }
}
