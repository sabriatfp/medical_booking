// lib/features/auth/ui/splash_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
// شاشات متوفّرة
import 'package:medical_booking/screens/login_screen.dart';
import 'package:medical_booking/screens/home_screen.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _bootRoute();
  }

  /// قراءة users/{uid} مع مهلة 10 ثوانٍ
  /// - عند المهلة أو الخطأ: نرجّع null ويعالجها الـ UI بفولباك آمن.
  Future<Map<String, dynamic>?> _safeGetUserDoc(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('✅ USER DOC EXISTS? ${snap.exists}');
      return snap.data();
    } on TimeoutException catch (_) {
      debugPrint('⌛ safeGetUserDoc TIMEOUT after 10s for $uid');
      return null;
    } on FirebaseException catch (e, st) {
      debugPrint(
        '❌ safeGetUserDoc FIREBASE ERROR → ${e.code} ${e.message}\n$st',
      );
      return null;
    } catch (e, st) {
      debugPrint('❌ safeGetUserDoc ERROR → $e\n$st');
      return null;
    }
  }

  // دالة تنقّل آمنة بعد أول build
  void _go(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );
    });
  }

  // ✅ الطبيب والمريض → HomeScreen (واجهة مشتركة تفرّق حسب الدور داخلها)
  void _goDoctor() => _go(const HomeScreen());
  void _goPatient() => _go(const HomeScreen());

  // مؤقتًا: إن لم تكن لديك شاشات كاملة لهذين الدورين
  void _goSecretary() => _go(const LoginScreen());
  void _goAdmin() => _go(const LoginScreen());

  void _goLogin() => _go(const LoginScreen());

  Future<void> _bootRoute() async {
    debugPrint('🚀 BOOT START');
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('👤 currentUser = ${user?.uid}');
    if (user == null) {
      debugPrint('➡️ NAV → Login (no user)');
      _goLogin();
      return;
    }

    final data = await _safeGetUserDoc(user.uid);
    debugPrint('📄 userDoc = $data');

    if (data == null) {
      // خطأ/Timeout: إرجاع آمن للّوجين
      _showSnack('تعذّر تحميل بيانات الحساب. إعادة التوجّه لتسجيل الدخول.');
      debugPrint('➡️ NAV → Login (userDoc null/timeout/error)');
      _goLogin();
      return;
    }

    final role = (data['role'] ?? '').toString();
    debugPrint('🧭 ROLE = $role');

    // ✅ المنهج المطلوب: الطبيب والمريض معًا → HomeScreen
    if (role == 'admin') {
      debugPrint('➡️ NAV → Admin (TEMP → Login)');
      _goAdmin();
    } else if (role == 'secretary') {
      debugPrint('➡️ NAV → Secretary (TEMP → Login)');
      _goSecretary();
    } else if (role == 'doctor') {
      debugPrint('➡️ NAV → Doctor → HomeScreen');
      _goDoctor();
    } else {
      // مريض أو دور غير معروف → HomeScreen
      debugPrint('➡️ NAV → Patient/Unknown → HomeScreen');
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
