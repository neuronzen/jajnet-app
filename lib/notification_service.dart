import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  debugPrint('BG: ${message.messageId}');
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      FirebaseMessaging.onBackgroundMessage(_bgHandler);

      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _fcm.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      _fcm.onTokenRefresh.listen(_saveToken);

      try {
        await _fcm.subscribeToTopic('jajnet_all');
        debugPrint('Subscribed to jajnet_all');
      } catch (e) {
        debugPrint('Subscribe error: $e');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage m) {
        debugPrint('FG: ${m.notification?.title}');
      });
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
