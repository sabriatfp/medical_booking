// lib/features/auth/ui/splash_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

// Screens
import 'package:medical_booking/screens/login_screen.dart';
import 'package:medical_booking/screens/home_screen.dart';

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

    // ✅ نضمن تشغيلها مرة واحدة فقط بعد جاهزية context
    if (!_initialized) {
      _initialized = true;
      _bootRoute();
    }
  }

  /// قراءة users/{uid} مع مهلة
  Future<Map<String, dynamic>?> _safeGetUserDoc(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8)); // ⏱️ قللنا المهلة

      debugPrint("✅ USER DOC EXISTS? ${snap.exists}");
      return snap.data();
    } on TimeoutException catch (_) {
      debugPrint('⌛ safeGetUserDoc TIMEOUT for $uid');
      return null;
    } catch (e, st) {
      debugPrint("❌ safeGetUserDoc ERROR → $e\n$st");
      return null;
    }
  }

  /// تنقّل آمن بعد أول build
  void _go(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );
    });
  }

  void _goLogin() => _go(const LoginScreen());
  void _goDoctor() => _go(const HomeScreen());
  void _goPatient() => _go(const HomeScreen());

  /// مؤقتًا
  void _goSecretary() => _go(const LoginScreen());
  void _goAdmin() => _go(const LoginScreen());

  Future<void> _bootRoute() async {
    final t = AppLocalizations.of(context)!;

    debugPrint("🚀 BOOT START");

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("➡️ NAV → Login (no user)");
      _goLogin();
      return;
    }

    debugPrint("👤 currentUser = ${user.uid}");

    final data = await _safeGetUserDoc(user.uid);
    debugPrint("📄 userDoc = $data");

    // ⚠️ لو فشل تحميل البيانات
    if (data == null) {
      _showSnack(t.failedToLoadUserData);
      debugPrint("➡️ NAV → Login (userDoc null)");
      _goLogin();
      return;
    }

    final role = (data['role'] ?? "").toString();
    debugPrint("🧭 ROLE = $role");

    // ✅ التوجيه حسب الدور
    if (role == "admin") {
      debugPrint("➡️ NAV → Admin");
      _goAdmin();
    } else if (role == "secretary") {
      debugPrint("➡️ NAV → Secretary");
      _goSecretary();
    } else if (role == "doctor") {
      debugPrint("➡️ NAV → Doctor → HomeScreen");
      _goDoctor();
    } else {
      debugPrint("➡️ NAV → Patient/Unknown → HomeScreen");
      _goPatient();
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
