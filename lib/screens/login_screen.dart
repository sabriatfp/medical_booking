import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import '../features/auth/ui/splash_wrapper.dart';
import 'role_selection_screen.dart';
import 'package:medical_booking/features/secretary/ui/secretary_code_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_login_screen.dart';
import '../providers/language_provider.dart';

/// --------------------------------------------------
/// SecretMultiTap (كما هو دون تغيير)
/// --------------------------------------------------
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
        if (mounted) setState(() => _tapCount = 0);
      });
    }

    _tapCount++;

    if (_tapCount >= widget.requiredTaps) {
      _resetTimer?.cancel();
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

/// --------------------------------------------------
/// LoginScreen (الإصدار المترجم بالكامل)
/// --------------------------------------------------
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
    final t = AppLocalizations.of(context)!;

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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) throw Exception(t.userDataNotFound);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashWrapper()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = _mapAuthError(e, t));
    } catch (_) {
      setState(() => error = t.unexpectedError);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openAdminLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: null, // تمت إزالة عنوان "تسجيل الدخول"

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ الشعار
                Center(
                  child: SecretMultiTap(
                    requiredTaps: 5,
                    windowInSeconds: 3,
                    onUnlocked: _openAdminLogin,
                    child: const Icon(
                      Icons.local_hospital,
                      size: 90,
                      color: Colors.teal,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ اسم التطبيق
                Center(
                  child: Text(
                    "MEDICAL BOOKING",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.teal,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ✅ البريد
                TextField(
                  controller: emailController,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t.email,
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ كلمة المرور
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t.password,
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                if (error != null)
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.right,
                  ),

                const SizedBox(height: 8),

                // ✅ زر الدخول
                ElevatedButton(
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
                      : Text(t.login),
                ),

                const SizedBox(height: 16),

                // ✅ إنشاء حساب جديد
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen(),
                      ),
                    );
                  },
                  child: Text(t.createNewAccount),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 14),

                // ✅ زر تغيير اللغة + زر السكريتير
                // ✅ زر تغيير اللغة + زر السكريتير
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // مهم
                  children: [
                    // ✅ عمود زر اللغة
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.language),
                          label: Text(t.language),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(t.chooseLanguage),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Provider.of<LanguageProvider>(
                                          context,
                                          listen: false,
                                        ).changeLanguage('ar');
                                        Navigator.pop(context);
                                      },
                                      child: Text(t.arabic),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Provider.of<LanguageProvider>(
                                          context,
                                          listen: false,
                                        ).changeLanguage('fr');
                                        Navigator.pop(context);
                                      },
                                      child: Text(t.french),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6), // ✅ نفس المسافة
                        const SizedBox(height: 16), // ✅ عنصر وهمي للمحاذاة
                      ],
                    ),

                    // ✅ عمود زر السكريتير
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.badge_outlined),
                          label: Text(t.secretarySpace),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const SecretaryCodeScreen(),
                              ),
                              (_) => false,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.secretaryHint,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _mapAuthError(FirebaseAuthException e, AppLocalizations t) {
    switch (e.code) {
      case 'invalid-email':
        return t.invalidEmail; // "البريد الإلكتروني غير صحيح"

      case 'user-not-found':
        return t.userNotFound; // "لا يوجد حساب بهذا البريد"

      case 'wrong-password':
        return t.wrongPassword; // "كلمة المرور غير صحيحة"

      case 'user-disabled':
        return t.userDisabled; // "هذا الحساب معطّل"

      case 'too-many-requests':
        return t.tooManyRequests; // "محاولات كثيرة، حاول لاحقًا"

      case 'network-request-failed':
        return t.networkError; // "تحقق من اتصال الإنترنت"

      default:
        return t.loginError; // "تعذر تسجيل الدخول"
    }
  }
}
