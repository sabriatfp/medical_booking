import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  final String role; // 'patient' أو (اختياري) 'doctor' لو أردت دمجاً
  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController(); // ✅ هاتف المريض

  bool loading = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { loading = true; error = null; });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      final usersRef =
          FirebaseFirestore.instance.collection('users').doc(cred.user!.uid);

      final baseData = {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.role == 'patient') {
        await usersRef.set({
          ...baseData,
          'role': 'patient',
          'phone': phone.text.trim(), // ✅ تخزين هاتف المريض
        });
      } else {
        // إن أردت دمج الطبيب هنا؛ نحن نستعمل DoctorRegisterScreen للطبيب
        await usersRef.set({
          ...baseData,
          'role': 'patient',
          'phone': phone.text.trim(),
        });
      }

      if (!mounted) return;

// بعد إنشاء حساب المريض، انتقل مباشرة إلى HomeScreen
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const HomeScreen()),
  (route) => false,
); // AuthGate سيوجهك حسب الدور
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email'        => 'البريد الإلكتروني غير صالح',
        'email-already-in-use' => 'هذا البريد مستخدم مسبقًا',
        'weak-password'        => 'كلمة المرور ضعيفة (6 أحرف على الأقل)',
        _                      => 'خطأ: ${e.message}',
      };
      setState(() => error = msg);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final isPatient = widget.role == 'patient';

    return Scaffold(
      appBar: AppBar(title: Text(isPatient ? 'تسجيل مريض' : 'تسجيل')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: _dec('الاسم الكامل', Icons.badge),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'أدخل اسمًا صحيحًا' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: email,
                        decoration: _dec('البريد الإلكتروني', Icons.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل البريد';
                          if (!v.contains('@')) return 'البريد غير صالح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: password,
                        decoration: _dec('كلمة المرور (6+ أحرف)', Icons.lock),
                        obscureText: true,
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'أدخل 6 أحرف على الأقل' : null,
                      ),
                      if (isPatient) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phone,
                          decoration: _dec('رقم الهاتف', Icons.phone),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              (v == null || v.trim().length < 6) ? 'أدخل رقم هاتف صحيح' : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (error != null)
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : _signUp,
                          icon: const Icon(Icons.person_add),
                          label: loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('إنشاء الحساب'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}