import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'main.dart';
import 'notice_detail.dart';

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
        _showForegroundBanner(m);
      });

      // === Deep-link handlers ===

      // App was in background, user tapped notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) async {
        debugPrint('Tapped (background): ${m.messageId}');
        await _handleTap(m);
      });

      // App was terminated, user tapped notification, app opened
      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        debugPrint('Tapped (terminated): ${initial.messageId}');
        // Delay a bit so Navigator is ready
        Future.delayed(const Duration(milliseconds: 1200), () {
          _handleTap(initial);
        });
      }
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  static Future<void> _handleTap(RemoteMessage m) async {
    try {
      final data = m.data;
      var noticeId = (data['noticeId'] ?? '').toString();
      // Fallback: if only title/body in data, still open detail
      final dataTitle = (data['title'] ?? m.notification?.title ?? '').toString();
      final dataBody  = (data['body']  ?? m.notification?.body  ?? '').toString();

      if (noticeId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('notices')
            .doc(noticeId)
            .get();
        if (doc.exists) {
          final d = doc.data()!;
          _openNotice(
            (d['title'] ?? dataTitle).toString(),
            (d['body'] ?? dataBody).toString(),
          );
          return;
        }
      }

      // No noticeId or notice deleted — show raw title/body if we have it
      if (dataTitle.isNotEmpty || dataBody.isNotEmpty) {
        _openNotice(dataTitle, dataBody);
      }
    } catch (e) {
      debugPrint('handleTap error: $e');
    }
  }

  static void _openNotice(String title, String body) {
    final nav = jajNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => NoticeDetailScreen(title: title, body: body),
    ));
  }

  /// লগইন/সাইনআপের পর কল করুন — তখনই ইউজার চেনা যায়, তাই token এখন সেভ হবে।
  static Future<void> saveTokenForCurrentUser() async {
    try {
      final t = await _fcm.getToken();
      if (t != null) await _saveToken(t);
    } catch (e) {
      debugPrint('saveTokenForCurrentUser error: $e');
    }
  }

  /// অ্যাপ খোলা থাকলে Android নিজে নোটিফিকেশন দেখায় না — তাই ভেতরে banner দেখাই।
  static void _showForegroundBanner(RemoteMessage m) {
    try {
      final ctx = jajNavigatorKey.currentContext;
      if (ctx == null) return;
      final title = (m.notification?.title ?? m.data['title'] ?? '').toString();
      final body = (m.notification?.body ?? m.data['body'] ?? '').toString();
      if (title.isEmpty && body.isEmpty) return;
      final messenger = ScaffoldMessenger.maybeOf(ctx);
      if (messenger == null) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty)
                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          action: SnackBarAction(
            label: 'দেখুন',
            onPressed: () {
              _handleTap(m);
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('foreground banner error: $e');
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
