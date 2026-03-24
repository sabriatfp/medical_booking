// lib/features/secretary/ui/secretary_code_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// لو لديك خدمة تحقق خارجية، أبقِها:
import 'package:medical_booking/features/secretary/data/verify_secretary_code.dart';
import 'package:medical_booking/screens/secretary/secretary_dashboard_screen.dart';

class SecretaryCodeScreen extends StatefulWidget {
  const SecretaryCodeScreen({super.key});
  @override
  State<SecretaryCodeScreen> createState() => _SecretaryCodeScreenState();
}

class _SecretaryCodeScreenState extends State<SecretaryCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // -----------------------------
  // Helpers: Auth + Secretary Session
  // -----------------------------

  /// إن لم يوجد مستخدم مسجّل: نسجّل مجهولاً. وإلا نستخدم الحالي (سواء مجهول أو لا).
  Future<User> _ensureUser() async {
    final auth = FirebaseAuth.instance;
    final cu = auth.currentUser;
    if (cu != null) {
      // debug
      // print('>>> Using existing uid=${cu.uid}, anon=${cu.isAnonymous}');
      return cu;
    }
    final cred = await auth.signInAnonymously();
    // print('>>> Signed in anonymously: uid=${cred.user?.uid}');
    return cred.user!;
  }

  /// يجلب الكود من المجموعة العامة: secretary_codes_public/{code}
  /// ويعيد doctorId + expiresAt (إن وجد). يرمي خطأ واضح عند أي خلل.
  Future<({String doctorId, String codeId, DateTime? expiresAt})>
  _fetchPublicCode(String rawCode) async {
    final codeId = rawCode.trim().toUpperCase();
    final ref = FirebaseFirestore.instance
        .collection('secretary_codes_public')
        .doc(codeId);
    final snap = await ref.get();

    if (!snap.exists) {
      throw StateError('الكود غير صحيح.');
    }
    final data = snap.data()!;
    final bool active = (data['active'] == true);
    if (!active) throw StateError('الكود غير مفعّل.');

    final String doctorId = (data['doctorId'] ?? '').toString();
    if (doctorId.isEmpty) throw StateError('doctorId غير موجود في الكود.');

    DateTime? expiresAt;
    final any = data['expiresAt'];
    if (any is Timestamp) {
      expiresAt = any.toDate();
      if (expiresAt.isBefore(DateTime.now())) {
        throw StateError('انتهت صلاحية الكود.');
      }
    }
    return (doctorId: doctorId, codeId: codeId, expiresAt: expiresAt);
    // (لو أردت التحقق الأعمق من انتهاء الصلاحية داخل القواعد، ما زال الكود أعلاه مناسبًا)
  }

  /// ينشئ/يحدّث جلسة السكرتير وفق القواعد المحدَّثة:
  /// secretary_sessions/{sessionId = uid_doctorId} with:
  /// { secretaryUid, doctorId, active, startedAt, codeId }
  Future<void> _createSecretarySession({
    required String uid,
    required String doctorId,
    required String codeId,
  }) async {
    final fs = FirebaseFirestore.instance;
    final sessionId = '${uid}_$doctorId'; // يطابق النمط المقبول في القواعد

    await fs.collection('secretary_sessions').doc(sessionId).set({
      'secretaryUid': uid,
      'doctorId': doctorId,
      'active': true,
      'startedAt': FieldValue.serverTimestamp(),
      'codeId':
          codeId, // ضروري لتتحقق القواعد من secretary_codes_public/{codeId}
    }, SetOptions(merge: true));
  }

  // -----------------------------
  // Verify flow
  // -----------------------------

  Future<void> _handleVerify({String? overrideCode}) async {
    final raw = (overrideCode ?? _codeCtrl.text).trim();
    if (raw.isEmpty) {
      setState(() => _error = 'أدخل الكود');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ✅ 1) تأمين مستخدم منذ البداية (حتى المجهول)
      final user =
          await _ensureUser(); // <-- أضف هذا في البداية، قبل أي قراءة من Firestore

      // (اختياري) لو عندك خدمة تحقق خارجية
      final verifier = SecretaryCodeVerifier();
      final res = await verifier.verify(raw);
      if (!res.ok) {
        if (!mounted) return;
        setState(() => _error = res.reason ?? 'تعذّر التحقق من الكود');
        return;
      }

      // ✅ 2) جلب وثيقة الكود من المجموعة العامة (تتطلب isSignedIn في القواعد)
      final pub = await _fetchPublicCode(raw);
      final doctorId = pub.doctorId;
      final codeId = pub.codeId;

      // ✅ 3) إنشاء/تحديث جلسة السكرتير بقيم مسموحة فقط
      await _createSecretarySession(
        uid: user.uid,
        doctorId: doctorId,
        codeId: codeId,
      );

      // 4) الانتقال
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SecretaryDashboardScreen(doctorId: doctorId),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'تعذّر تسجيل الدخول. أعد المحاولة.';
      if (e.code == 'operation-not-allowed') {
        msg =
            'تسجيل الدخول المجهول غير مفعّل. فعّله من Firebase Console ثم أعد المحاولة.';
      } else if (e.code == 'network-request-failed') {
        msg = 'مشكلة في الاتصال بالشبكة. تحقّق من الإنترنت ثم أعد المحاولة.';
      }
      setState(() => _error = msg);
      return;
    } on FirebaseException catch (e) {
      // أهم حالة متوقعة هنا: permission-denied من secretary_sessions
      if (!mounted) return;
      final msg = e.code == 'permission-denied'
          ? 'تعذّر إنشاء جلسة السكرتير: صلاحيات غير كافية.\nتحقّق من قواعد secretary_sessions ثم أعد المحاولة.'
          : 'تعذّر إتمام العملية. (${e.code})';
      setState(() => _error = msg);
      return;
    } on StateError catch (e) {
      // كود غير صحيح / غير مفعّل / منتهي الصلاحية
      if (!mounted) return;
      setState(() => _error = e.message);
      return;
    } catch (e, st) {
      // أي خطأ آخر
      debugPrint('SecretaryCode Generic ERROR: $e\n$st');
      if (!mounted) return;
      setState(() => _error = 'تعذّر التحقق من الكود');
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('فضاء السكريتير')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل كود السكرتير الذي زوّدك به الطبيب',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeCtrl,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'كود السكرتير',
                    hintText: 'مثال: SEC-AB23K7',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _handleVerify(),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _handleVerify,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: const Text('دخول'),
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
