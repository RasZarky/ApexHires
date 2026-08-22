import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// OneSignal configuration via environment variables.
/// Set via --dart-define-from-file=.env or individual --dart-define flags.
const String _oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');

/// Background message handler — required by Firebase
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  debugPrint('Background message received');
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize OneSignal and FCM integration
  Future<void> initialize(String userId) async {
    if (_oneSignalAppId.isEmpty) {
      debugPrint(
        '⚠️  OneSignal not configured. Set ONESIGNAL_APP_ID.\n'
        '   Push notifications will be disabled.\n'
        '   Get free tier at https://onesignal.com',
      );
      return;
    }

    // Initialize OneSignal
    OneSignal.initialize(_oneSignalAppId);

    // Request permission (shows native prompt)
    await OneSignal.Notifications.requestPermission(true);

    // Set external user ID so we can target this device from the Edge Function
    await OneSignal.login(userId);

    // Tag user with Firebase UID and role for dashboard filtering
    await OneSignal.User.addTags({
      'firebase_uid': userId,
      'role': 'user',
    });

    // Handle foreground notifications
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('Foreground notification: ${event.notification.title}');
      // Do NOT call event.preventDefault() — let the notification display
    });

    // Handle notification taps (app in background or killed)
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('Notification tapped: ${event.notification.title}');
      _handleNotificationTap(event.notification);
    });

    debugPrint('✅ OneSignal initialized for user $userId');
  }

  /// Remove tags on logout
  Future<void> clearUser() async {
    await OneSignal.logout();
    await OneSignal.User.removeTags(['firebase_uid', 'role']);
  }

  /// Send a notification to a target user.
  ///
  /// 1. Stores in-app notification in Firestore (for the notification center)
  /// 2. Calls Supabase Edge Function to send push via OneSignal REST API
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    // 1. Store in-app notification in Firestore
    try {
      await _firestore.collection('notifications').add({
        'user_id': targetUserId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ In-app notification stored for $targetUserId: $title');
    } catch (e) {
      debugPrint('⚠️ Failed to store notification: $e');
    }

    // 2. Send push notification via Supabase Edge Function
    _sendPushNotification(
      targetUserId: targetUserId,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  /// Fire-and-forget push notification via Supabase Edge Function.
  /// Failures are logged but don't block the caller.
  void _sendPushNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'send-notification',
        body: {
          'targetUserId': targetUserId,
          'title': title,
          'body': body,
          'type': type,
          'data': data,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ Push notification sent to $targetUserId');
      } else {
        debugPrint('⚠️ Push notification failed (status ${response.status}): ${response.data}');
      }
    } catch (e) {
      debugPrint('⚠️ Push notification error: $e');
    }
  }

  void _handleNotificationTap(OSNotification notification) {
    final data = notification.additionalData;
    if (data != null) {
      final type = data['type'] ?? '';
      debugPrint('Notification type: $type, data: $data');
    }
  }
}
