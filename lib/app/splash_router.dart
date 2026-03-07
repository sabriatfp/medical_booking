import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// عدّل المسارات حسب مشروعك
import 'package:medical_booking/screens/secretary/secretary_dashboard_screen.dart';
import 'package:medical_booking/screens/login_screen.dart';
import 'package:medical_booking/screens/home_screen.dart';

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    _routeSafely();
  }

  Future<void> _routeSafely() async {
    // نحمي من أي استثناءات غير متوقعة
    try {
      await _routeWithTimeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[SplashRouter] Route error: $e');
      _go(const LoginScreen()); // سقوط آمن للـ Login
    }
  }

  Future<void> _routeWithTimeout(Duration timeout) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    debugPrint(
      '[SplashRouter] start, user=${user?.uid}, anon=${user?.isAnonymous}',
    );

    // 1) لا يوجد مستخدم => شاشة الدخول
    if (user == null) {
      _go(const LoginScreen());
      return;
    }

    // 2) سكرتير (Anonymous) => افحص جلسة السكريتير مع timeout
    if (user.isAnonymous) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('secretary_sessions')
            .doc(user.uid)
            .get()
            .timeout(timeout);

        debugPrint('[SplashRouter] secretary_sessions exists=${doc.exists}');

        if (!doc.exists) {
          await auth.signOut();
          _go(const LoginScreen());
          return;
        }

        final data = doc.data()!;
        final String doctorId = (data['doctorId'] ?? '').toString();
        final ts = data['expiresAt'];
        final DateTime? expiresAt = (ts is Timestamp) ? ts.toDate() : null;

        final bool valid =
            doctorId.isNotEmpty &&
            expiresAt != null &&
            expiresAt.isAfter(DateTime.now());

        debugPrint(
          '[SplashRouter] secretary valid=$valid, doctorId=$doctorId, exp=$expiresAt',
        );

        if (!valid) {
          await auth.signOut();
          _go(const LoginScreen());
          return;
        }

        // ✅ جلسة سكرتير صالحة → افتح فضاء السكريتير مباشرة
        _go(SecretaryDashboardScreen(doctorId: doctorId));
        return;
      } on TimeoutException {
        debugPrint('[SplashRouter] secretary_sessions timeout -> login');
        // شبكة بطيئة/مقطوعة: لا نعلّق المستخدم، نرجع للـ login
        _go(const LoginScreen());
        return;
      } catch (e) {
        debugPrint('[SplashRouter] secretary_sessions error: $e');
        await auth.signOut();
        _go(const LoginScreen());
        return;
      }
    }

    // 3) مستخدم مسجّل (طبيب/مريض) → إلى الصفحة الرئيسية
    _go(const HomeScreen());
  }

  void _go(Widget page) {
    if (!mounted || _routed) return;
    _routed = true;

    // نؤجّل النفيجيشن لما بعد أول Frame لتفادي أي تعارض
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
