// lib/features/admin/ui/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/features/admin/ui/admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInAdmin() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) تسجيل الدخول
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final uid = cred.user?.uid;
      if (uid == null) throw Exception('UID غير متاح');

      // 2) جلب وثيقة المستخدم للتحقق من الدور
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        // لا نترك الجلسة مفتوحة
        await FirebaseAuth.instance.signOut();
        throw Exception('لا تملك صلاحية الوصول');
      }

      final role = (doc.data()?['role'] ?? '') as String;
      if (role.toLowerCase() != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw Exception('ممنوع الوصول — هذا الحساب ليس أدمن');
      }

      if (!mounted) return;

      // 3) نجاح → الانتقال إلى لوحة الأدمن
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // رسائل واضحة للمطوّر والمستخدم
      String msg;
      switch (e.code) {
        case 'invalid-email':
          msg = 'البريد غير صحيح';
          break;
        case 'user-disabled':
          msg = 'تم تعطيل هذا الحساب';
          break;
        case 'user-not-found':
        case 'wrong-password':
          msg = 'البريد أو كلمة المرور غير صحيحة';
          break;
        default:
          msg = 'تعذر تسجيل الدخول: ${e.message ?? e.code}';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendResetEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'أدخل البريد أولًا لإرسال رابط الاستعادة');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رابط إعادة تعيين كلمة المرور')),
      );
    } catch (e) {
      setState(() => _error = 'تعذر إرسال رابط الاستعادة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(
        context,
      ).unfocus(), // إغلاق الكيبورد عند اللمس خارج الحقول
      child: Scaffold(
        appBar: AppBar(title: const Text('تسجيل دخول الأدمن')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // أيقونة/عنوان بسيط
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 64,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'دخول الأدمن',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // البريد
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'أدخل البريد';
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'صيغة البريد غير صحيحة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // كلمة المرور
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'إظهار' : 'إخفاء',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'أدخل كلمة المرور';
                        if ((v ?? '').length < 6) return 'كلمة المرور قصيرة';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.right,
                        ),
                      ),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _signInAdmin,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock_open),
                        label: const Text('دخول الأدمن'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _loading ? null : _sendResetEmail,
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // تلميح صغير: هذه شاشة خاصة
                    const Center(
                      child: Text(
                        'هذه الشاشة خاصة بالأدمن.\nتم الوصول إليها عبر الحركة السرّية.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
