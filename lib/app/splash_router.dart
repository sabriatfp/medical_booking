// lib/features/auth/ui/splash_router.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
// Screens
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
    try {
      await _routeWithTimeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("[SplashRouter] Route error: $e");
      _go(const LoginScreen());
    }
  }

  Future<void> _routeWithTimeout(Duration timeout) async {
    final t = AppLocalizations.of(context)!;

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    debugPrint(
      "[SplashRouter] start, user=${user?.uid}, anon=${user?.isAnonymous}",
    );

    // 1) لا يوجد مستخدم
    if (user == null) {
      _go(const LoginScreen());
      return;
    }

    // 2) سكرتير (Anonymous)
    if (user.isAnonymous) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('secretary_sessions')
            .doc(user.uid)
            .get()
            .timeout(timeout);

        debugPrint("[SplashRouter] secretary_sessions exists=${doc.exists}");

        if (!doc.exists) {
          await auth.signOut();
          _go(const LoginScreen());
          return;
        }

        final data = doc.data()!;
        final doctorId = (data['doctorId'] ?? '').toString();

        final ts = data['expiresAt'];
        final expiresAt = ts is Timestamp ? ts.toDate() : null;

        final valid =
            doctorId.isNotEmpty &&
            expiresAt != null &&
            expiresAt.isAfter(DateTime.now());

        debugPrint(
          "[SplashRouter] secretary valid=$valid, doctorId=$doctorId, exp=$expiresAt",
        );

        if (!valid) {
          await auth.signOut();
          _go(const LoginScreen());
          return;
        }

        _go(SecretaryDashboardScreen(doctorId: doctorId));
        return;
      } on TimeoutException {
        debugPrint("[SplashRouter] secretary_sessions timeout -> login");
        _go(const LoginScreen());
        return;
      } catch (e) {
        debugPrint("[SplashRouter] secretary_sessions error: $e");
        await auth.signOut();
        _go(const LoginScreen());
        return;
      }
    }

    // 3) طبيب/مريض -> الصفحة الرئيسية
    _go(const HomeScreen());
  }

  void _go(Widget page) {
    if (!mounted || _routed) return;
    _routed = true;

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
