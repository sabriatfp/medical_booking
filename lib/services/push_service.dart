// lib/services/push_service.dart
// ===============================================
// يعمل الآن بدون Firebase (Local Notifications)
// لاحقًا: فعّل FCM بتغيير useFirebase إلى true
// ===============================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ❌ لا نستورد Firebase الآن لتجنب الأخطاء
// ✅ لاحقًا بعد التفعيل: أزل التعليقات عن التالي
// import 'dart:io' show Platform;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

typedef NotificationTapHandler = void Function(Map<String, dynamic> data);

// راية التحكم العامة
const bool useFirebase = false; // ❌ الآن بدون Firebase — لاحقًا اجعلها true

// =======================
// ⬇️⬇️ مهم: Top-level callback للخلفية
// يجب أن يكون Top-level + entry-point
// =======================
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // نفك الـ payload ونستدعي نفس منطق onTap عبر السيرفيس
  final payload = response.payload;
  final data =
      PushService.instance._tryParseJson(payload) ?? {'payload': payload ?? ''};
  PushService.instance._invokeTapHandler(data);
}

class PushService {
  PushService._internal();
  static final PushService instance = PushService._internal();

  // -----------------------------
  // Local Notifications (الآن)
  // -----------------------------
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  NotificationTapHandler? _onTap;

  // (لاحقًا) FCM objects
  // final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  // String? _lastSavedToken;

  /// التهيئة العامة
  Future<void> init({NotificationTapHandler? onNotificationTap}) async {
    if (_initialized) return;
    _onTap = onNotificationTap;

    // ==========================
    // 1) Local Notifications init
    // ==========================
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      initSettings,
      // ⬇️ فورغراوند/عادي
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        final data = _tryParseJson(payload) ?? {'payload': payload ?? ''};
        _invokeTapHandler(data);
      },
      // ⬇️ الخلفية: يجب أن تكون دالة Top-level مُعلّمة entry-point
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // طلب أذونات الإشعارات (iOS + Android 13+)
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _local
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // ==========================
    // 2) (اختياري) إشعار تجريبي
    // ==========================
    await showLocalNotification(
      title: 'الإشعارات مفعّلة محليًا',
      body: 'سيتم تفعيل FCM لاحقًا عند تشغيل Firebase',
    );

    _initialized = true;

    // ==========================
    // 3) لاحقًا: تفعيل FCM
    // ==========================
    if (useFirebase) {
      // --- أزل التعليقات عند التفعيل ---
      // await _initFcmLayer();
    }
  }

  // ==========================
  // واجهات عامة مستقرة
  // ==========================
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = data == null ? null : jsonEncode(data);

    const android = AndroidNotificationDetails(
      'local_channel',
      'Notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  /// استدعاء عند ضغط المستخدم على الإشعار
  void _invokeTapHandler(Map<String, dynamic> data) {
    try {
      if (_onTap != null) {
        _onTap!(data);
      } else {
        debugPrint('[Push] onNotificationTap غير ممرّر. data=$data');
      }
    } catch (e, st) {
      debugPrint('[Push] onNotificationTap threw: $e\n$st');
    }
  }

  Map<String, dynamic>? _tryParseJson(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final obj = jsonDecode(payload);
      if (obj is Map<String, dynamic>) return obj;
      return null;
    } catch (_) {
      return null;
    }
  }

  // تنظيف محلي (لا شيء ضروري الآن)
  Future<void> signOutCleanup() async {
    // لاحقًا مع FCM:
    // await _fcm.deleteToken();
  }

  // الحصول على التوكن الحالي (محليًا: null)
  Future<String?> getToken() async {
    if (!useFirebase) return null;
    // لاحقًا:
    // return await _fcm.getToken();
    return null;
  }

  // ============================================================
  // ====================  FCM Layer (لاحقًا)  ==================
  // ============================================================
  // Future<void> _initFcmLayer() async { ... }
  // Future<void> _saveToken(String token) async { ... }
  // Future<String?> _determineUserRole(String uid) async { ... }
}
