import 'dart:async'; // غير ضرورية هنا
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔁 CHANGED: لن نوجّه مباشرة لـ HomeScreen بعد الآن
// import 'home_screen.dart'; // 🧹 CLEANUP: لم نعد نستخدمه هنا
import '../features/auth/ui/splash_wrapper.dart';

import 'role_selection_screen.dart';
// شاشة إدخال كود السكريتير (جديدة)
import 'package:medical_booking/features/secretary/ui/secretary_code_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_login_screen.dart';

/// ------------------------------
/// SecretMultiTap ...
/// ------------------------------
class SecretMultiTap extends StatefulWidget {
  final Widget child;
  final int requiredTaps;
  final int windowInSeconds;
  final VoidCallback onUnlocked;
  final bool hapticOnEachTap;
  final Duration flashDuration;

  const SecretMultiTap({
    super.key,
    required this.child,
    required this.onUnlocked,
    this.requiredTaps = 5,
    this.windowInSeconds = 3,
    this.hapticOnEachTap = true,
    this.flashDuration = const Duration(milliseconds: 120),
  });

  @override
  State<SecretMultiTap> createState() => _SecretMultiTapState();
}

class _SecretMultiTapState extends State<SecretMultiTap> {
  int _tapCount = 0;
  Timer? _resetTimer;

  bool _dim = false;
  Timer? _flashTimer;

  void _flashOnce() {
    setState(() => _dim = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(widget.flashDuration, () {
      if (mounted) setState(() => _dim = false);
    });
  }

  void _handleTap() {
    if (widget.hapticOnEachTap) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }

    _flashOnce();

    if (_tapCount == 0) {
      _resetTimer?.cancel();
      _resetTimer = Timer(Duration(seconds: widget.windowInSeconds), () {
        if (mounted) {
          setState(() {
            _tapCount = 0;
          });
        }
      });
    }

    setState(() {
      _tapCount++;
    });

    if (_tapCount >= widget.requiredTaps) {
      _resetTimer?.cancel();
      _resetTimer = null;
      _tapCount = 0;

      widget.onUnlocked();
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flickerChild = AnimatedOpacity(
      duration: widget.flashDuration,
      opacity: _dim ? 0.7 : 1.0,
      child: widget.child,
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: flickerChild,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      final uid = cred.user!.uid;
      // 🧹 CLEANUP: ليس ضرورياً هنا؛ SplashWrapper سيقرأ users/{uid} ويقرر الوجهة
      // إذا أردت فقط التحقق من وجود الوثيقة دون استخدامها يمكنك الإبقاء على السطور التالية:
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("بيانات المستخدم غير موجودة");
      }

      if (!mounted) return;

      // 🔁 CHANGED: وجّه دائمًا إلى SplashWrapper (هو الذي يرسل Doctor/Patient إلى HomeScreen المشتركة)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashWrapper()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? "حدث خطأ في تسجيل الدخول");
    } catch (e) {
      setState(() => error = "حدث خطأ غير متوقع");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openAdminLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل الدخول")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- اللوجو: منطقة النقر السرّية ---
                Center(
                  child: SecretMultiTap(
                    requiredTaps: 5,
                    windowInSeconds: 3,
                    hapticOnEachTap: true,
                    onUnlocked: _openAdminLogin,
                    child: const Icon(
                      Icons.local_hospital,
                      size: 80,
                      color: Colors.teal,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // البريد وكلمة المرور
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: "البريد الإلكتروني",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "كلمة المرور",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.right,
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("دخول"),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen(),
                      ),
                    );
                  },
                  child: const Text('إنشاء حساب جديد'),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text("فضاء السكريتير"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecretaryCodeScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "سكرتير؟ ادخل عبر الكود الذي زوّدك به الطبيب.",
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// Placeholder للأدمن ... (كما هو)
/// ------------------------------
