// lib/features/auth/ui/splash_router.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Screens
import 'package:medical_booking/screens/secretary/secretary_dashboard_screen.dart';
import 'package:medical_booking/screens/login_screen.dart';
import 'package:medical_booking/screens/home_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_dashboard_screen.dart';

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
    _route();
  }

  Future<void> _route() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // 1️⃣ لا يوجد مستخدم
    if (user == null) {
      _go(const LoginScreen());
      return;
    }

    try {
      // 2️⃣ اقرأ users/{uid}
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) {
        // مستخدم بدون role → مريض
        _go(const HomeScreen());
        return;
      }

      final data = snap.data()!;
      final role = data['role'];

      // ✅ Admin
      if (role == 'admin') {
        _go(const AdminDashboardScreen());
        return;
      }

      // ✅ Secretary
      if (role == 'secretary' && data['activeSecretaryDoctorId'] != null) {
        _go(
          SecretaryDashboardScreen(doctorId: data['activeSecretaryDoctorId']),
        );
        return;
      }

      // ✅ Patient (default)
      _go(const HomeScreen());
    } catch (e) {
      debugPrint('[SplashRouter] error: $e');
      await auth.signOut();
      _go(const LoginScreen());
    }
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
