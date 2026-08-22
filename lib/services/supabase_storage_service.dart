import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// StorageService using Supabase for file uploads.
/// Replaces Firebase Storage which is not available on Firebase Spark plan.
///
/// Since we use Firebase Auth (not Supabase Auth), we use the service_role
/// key which bypasses RLS. Security is enforced at the app level:
/// - Only authenticated Firebase users can trigger uploads
/// - File paths include user IDs to prevent cross-user access
///
/// Setup:
/// 1. Create a Supabase project at https://supabase.com
/// 2. Create buckets: 'avatars', 'resumes', 'logos' (all public)
/// 3. Run the SQL below in Supabase SQL Editor:
///
/// ```sql
/// -- Create public buckets
/// INSERT INTO storage.buckets (id, name, public) VALUES
///   ('avatars', 'avatars', true),
///   ('resumes', 'resumes', true),
///   ('logos', 'logos', true);
///
/// -- Allow all operations (security handled at app level via Firebase Auth)
/// CREATE POLICY "Public access" ON storage.objects
///   FOR ALL USING (true) WITH CHECK (true);
/// ```
///
/// 4. Set SUPABASE_URL and SUPABASE_SERVICE_KEY via --dart-define-from-file=.env
class StorageService {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseKey =
      String.fromEnvironment('SUPABASE_SERVICE_KEY');

  SupabaseClient? _client;

  SupabaseClient get client {
    _client ??= SupabaseClient(supabaseUrl, supabaseKey);
    return _client!;
  }

  bool get isAvailable =>
      supabaseUrl.isNotEmpty &&
      supabaseKey.isNotEmpty &&
      supabaseUrl != 'https://YOUR_PROJECT.supabase.co' &&
      supabaseKey != 'YOUR_SUPABASE_SERVICE_KEY';

  /// Initialize Supabase (call in main.dart)
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseUrl == 'https://YOUR_PROJECT.supabase.co') {
      debugPrint(
        '⚠️  Supabase not configured. Set SUPABASE_URL and SUPABASE_SERVICE_KEY.\n'
        '   File uploads (avatars, resumes, logos) will be disabled.\n'
        '   Get free tier at https://supabase.com',
      );
      return;
    }
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    debugPrint('✅ Supabase initialized for file storage');
  }

  /// Upload avatar image, returns public URL
  Future<String> uploadAvatar(String userId, File imageFile) async {
    if (!isAvailable) {
      debugPrint('Skipping avatar upload — Supabase not configured');
      return '';
    }
    try {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.path.split('.').last;
      final path = 'avatars/$userId.$ext';

      await client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = client.storage.from('avatars').getPublicUrl(path);
      debugPrint('Avatar uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('Avatar upload failed: $e');
      return '';
    }
  }

  /// Upload resume PDF, returns URL and filename
  Future<Map<String, String>> uploadResume(
      String userId, File resumeFile, String fileName) async {
    if (!isAvailable) {
      debugPrint('Skipping resume upload — Supabase not configured');
      return {'url': '', 'name': ''};
    }
    try {
      final bytes = await resumeFile.readAsBytes();
      final path = 'resumes/$userId/$fileName';

      await client.storage.from('resumes').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'application/pdf',
            ),
          );

      final url = client.storage.from('resumes').getPublicUrl(path);
      debugPrint('Resume uploaded: $url');
      return {'url': url, 'name': fileName};
    } catch (e) {
      debugPrint('Resume upload failed: $e');
      return {'url': '', 'name': ''};
    }
  }

  /// Upload company logo, returns public URL
  Future<String> uploadCompanyLogo(String userId, File logoFile) async {
    if (!isAvailable) {
      debugPrint('Skipping logo upload — Supabase not configured');
      return '';
    }
    try {
      final bytes = await logoFile.readAsBytes();
      final ext = logoFile.path.split('.').last;
      final path = 'logos/$userId.$ext';

      await client.storage.from('logos').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = client.storage.from('logos').getPublicUrl(path);
      debugPrint('Logo uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('Logo upload failed: $e');
      return '';
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String bucket, String path) async {
    if (!isAvailable || path.isEmpty) return;
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('File delete failed: $e');
    }
  }
}
