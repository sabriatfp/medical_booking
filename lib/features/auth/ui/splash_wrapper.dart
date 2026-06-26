// lib/features/auth/ui/splash_wrapper.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

// Screens
import 'package:medical_booking/screens/login_screen.dart';
import 'package:medical_booking/screens/home_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_dashboard_screen.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _bootRoute();
    }
  }

  /// ✅ قراءة userDoc مع fallback للـ cache
  Future<Map<String, dynamic>?> _safeGetUserDoc(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));

      return snap.data();
    } on TimeoutException {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));

        return snap.data();
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  void _go(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (_) => false,
      );
    });
  }

  void _goLogin() => _go(const LoginScreen());
  void _goHome() => _go(const HomeScreen());
  void _goAdmin() => _go(const AdminDashboardScreen());

  Future<void> _bootRoute() async {
    final t = AppLocalizations.of(context)!;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _goLogin();
      return;
    }

    await user.reload();

    Map<String, dynamic>? data = await _safeGetUserDoc(user.uid);

    if (data == null) {
      await Future.delayed(const Duration(milliseconds: 600));
      data = await _safeGetUserDoc(user.uid);

      if (data == null) {
        _showSnack(t.failedToLoadUserData);
        await Future.delayed(const Duration(milliseconds: 800));
        _goLogin();
        return;
      }
    }

    final role = (data['role'] ?? '').toString();
    if (role.isEmpty) {
      _showSnack(t.invalidUserRole);
      await Future.delayed(const Duration(milliseconds: 800));
      _goLogin();
      return;
    }

    // ✅ التوجيه بسيط: الجميع إلى Home
    switch (role) {
      case 'admin':
        _goAdmin();
        break;

      case 'doctor':
        _goHome(); // HomeScreen فيه منطق doctor
        break;

      case 'patient':
        _goHome();
        break;

      default:
        _showSnack(t.invalidUserRole);
        await Future.delayed(const Duration(milliseconds: 800));
        _goLogin();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
