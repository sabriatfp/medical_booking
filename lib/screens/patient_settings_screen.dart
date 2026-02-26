import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/screens/notification_settings_screen.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  late String _uid;
  late DocumentReference<Map<String, dynamic>> _patientDoc;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnack('الرجاء تسجيل الدخول أولاً');
        Navigator.of(context).pop();
      });
      return;
    }
    _uid = user.uid;
    _patientDoc = FirebaseFirestore.instance.collection('patients').doc(_uid);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final snap = await _patientDoc.get();
      final data = snap.data() ?? {};

      _emailCtrl.text = user?.email ?? (data['email'] as String? ?? '');
      _phoneCtrl.text = (data['phone'] as String?) ?? (user?.phoneNumber ?? '');

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('تعذر تحميل بيانات الحساب: $e');
    }
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _reauthenticateIfNeeded({
    required String currentPassword,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('لا يوجد مستخدم مسجل دخول.');
      return false;
    }
    final email = user.email;
    if (email == null) {
      return true; // حساب بدون إيميل (مزود آخر) لا نعيد المصادقة هنا
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      return true;
    } on FirebaseAuthException catch (e) {
      _showSnack(
        e.code == 'wrong-password'
            ? 'كلمة المرور الحالية غير صحيحة'
            : 'فشل إعادة المصادقة: ${e.message ?? e.code}',
      );
      return false;
    } catch (e) {
      _showSnack('فشل إعادة المصادقة: $e');
      return false;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('لا يوجد مستخدم مسجل دخول.');
      return;
    }

    final newEmail = _emailCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();

    final emailChanged =
        (newEmail.isNotEmpty && newEmail != (user.email ?? ''));
    final passwordChanged = newPassword.isNotEmpty;
    final phoneChanged = newPhone
        .isNotEmpty; // سنحفظه في Firestore (توثيق الهاتف يتم عبر التدفق أدناه)

    if (!emailChanged && !passwordChanged && !phoneChanged) {
      _showSnack('لا توجد تغييرات للحفظ.');
      return;
    }

    setState(() => _saving = true);

    try {
      // إعادة المصادقة إذا كنا سنغير الإيميل أو كلمة المرور
      if (emailChanged || passwordChanged) {
        final ok = await _reauthenticateIfNeeded(
          currentPassword: _currentPasswordCtrl.text,
        );
        if (!ok) {
          setState(() => _saving = false);
          return;
        }
      }

      // 1) تحديث الإيميل في Auth
      if (emailChanged) {
        await user.updateEmail(newEmail);
        // اختياري: تفعيل تأكيد البريد قبل الإبدال النهائي:
        // await user.verifyBeforeUpdateEmail(newEmail);
      }

      // 2) تحديث كلمة المرور في Auth
      if (passwordChanged) {
        await user.updatePassword(newPassword);
      }

      // 3) تحديث Firestore (email/phone)
      final updateData = <String, dynamic>{};
      if (emailChanged) updateData['email'] = newEmail;
      if (phoneChanged) updateData['phone'] = newPhone;
      if (updateData.isNotEmpty) {
        await _patientDoc.set(updateData, SetOptions(merge: true));
      }

      _showSnack('تم حفظ التغييرات بنجاح.');
    } on FirebaseAuthException catch (e) {
      _showSnack('فشل الحفظ: ${e.message ?? e.code}');
    } catch (e) {
      _showSnack('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // تدفق تحقق رقم الهاتف عبر SMS (يفتح شاشة مصغّرة داخل التطبيق)
  void _startPhoneVerificationFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhoneVerificationScreen(
          initialPhone: _phoneCtrl.text.trim(),
          onVerified: (verifiedPhone) async {
            _phoneCtrl.text = verifiedPhone;
            try {
              await _patientDoc.set({
                'phone': verifiedPhone,
              }, SetOptions(merge: true));
              _showSnack('تم تحديث رقم الهاتف.');
            } catch (e) {
              _showSnack('تعذر تحديث رقم الهاتف في البيانات: $e');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات المريض'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== البريد =====
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'example@mail.com',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'الرجاء إدخال البريد';
                final emailRegex = RegExp(
                  r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
                );
                if (!emailRegex.hasMatch(value)) return 'بريد غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ===== كلمة المرور الحالية (يلزم عند تعديل البريد/كلمة المرور) =====
            TextFormField(
              controller: _currentPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية (للتأكيد)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) {
                final user = FirebaseAuth.instance.currentUser;
                final emailChanged =
                    _emailCtrl.text.trim().isNotEmpty &&
                    _emailCtrl.text.trim() != (user?.email ?? '');
                final newPwdEntered = _newPasswordCtrl.text.trim().isNotEmpty;
                if (emailChanged || newPwdEntered) {
                  if ((v ?? '').isEmpty) {
                    return 'أدخل كلمة المرور الحالية للتأكيد';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ===== كلمة المرور الجديدة =====
            TextFormField(
              controller: _newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة (اختياري)',
                prefixIcon: Icon(Icons.lock),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return null;
                if (value.length < 6) {
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ===== رقم الهاتف =====
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                hintText: '+216 5x xxx xxx',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: TextButton(
                  onPressed: _startPhoneVerificationFlow,
                  child: const Text('تحقق عبر SMS'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== زر الحفظ =====
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveChanges,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ التغييرات'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 24),

            // ===== إعدادات الإشعارات (كما كانت لديك) =====
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('إعدادات الإشعارات'),
              subtitle: const Text(
                'تفعيل/تعطيل وإدارة الأجهزة المستلمة للإشعارات',
              ),
              onTap: () {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) {
                  _showSnack('الرجاء تسجيل الدخول أولًا');
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationSettingsScreen(
                      role: UserRole.patient,
                      userId: uid,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'ملاحظة: تغيير البريد أو كلمة المرور يتطلب تأكيدًا بكلمة المرور الحالية لحماية حسابك.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة مبسطة لتوثيق الهاتف عبر SMS وتحديثه في Auth
class _PhoneVerificationScreen extends StatefulWidget {
  final String initialPhone;
  final ValueChanged<String> onVerified;

  const _PhoneVerificationScreen({
    required this.initialPhone,
    required this.onVerified,
  });

  @override
  State<_PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<_PhoneVerificationScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _verificationId;
  bool _sending = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showSnack('أدخل رقم الهاتف أولاً');
      return;
    }
    setState(() => _sending = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // أحيانًا يتم التحقق التلقائي على Android
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await user.updatePhoneNumber(credential);
            widget.onVerified(phone);
            if (mounted) Navigator.of(context).pop();
          }
        } catch (e) {
          _showSnack('فشل التحقق التلقائي: $e');
        }
      },
      verificationFailed: (e) {
        _showSnack('فشل إرسال الرمز: ${e.message}');
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _showSnack('تم إرسال رمز التحقق عبر SMS.');
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if ((_verificationId ?? '').isEmpty || code.isEmpty) {
      _showSnack('أدخل الرمز الذي وصلك عبر SMS');
      return;
    }
    setState(() => _verifying = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('لا يوجد مستخدم مسجل دخول.');
        setState(() => _verifying = false);
        return;
      }
      await user.updatePhoneNumber(credential);
      widget.onVerified(_phoneCtrl.text.trim());
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showSnack('فشل التحقق: ${e.message ?? e.code}');
    } catch (e) {
      _showSnack('خطأ أثناء التحقق: $e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحقق رقم الهاتف')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _sending ? null : _sendCode,
            icon: const Icon(Icons.sms),
            label: Text(_sending ? 'جار الإرسال...' : 'إرسال رمز عبر SMS'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'رمز التحقق',
              prefixIcon: Icon(Icons.shield),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _verifying ? null : _verifyCode,
            icon: const Icon(Icons.verified),
            label: Text(_verifying ? 'جار التحقق...' : 'تأكيد الرمز'),
          ),
        ],
      ),
    );
  }
}
