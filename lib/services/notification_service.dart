import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      await _saveToken(token);

      _messaging.onTokenRefresh.listen(_saveToken);
    }

    FirebaseMessaging.onMessage.listen(handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'tokenUpdatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  static void handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _showLocalNotification(notification.title, notification.body);
  }

  static void _handleMessageTap(RemoteMessage message) {}

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void _showLocalNotification(String? title, String? body) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFE11D2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            if (body != null)
              Text(body, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  static Future<void> sendWorkoutNotification({
    required String userId,
    required String displayName,
    required String workoutTitle,
    required String category,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'workout_logged',
      'fromUserId': userId,
      'fromDisplayName': displayName,
      'workoutTitle': workoutTitle,
      'category': category,
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }
}
