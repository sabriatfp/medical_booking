// lib/features/secretary/ui/secretary_code_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// خدمة التحقق حسب مشروعك (تبقى كما هي)
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

  /// يضمن وجود مستخدم Anonymous لتعلُّق القواعد بـ request.auth.uid
  Future<User> _ensureAnonUser() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null || auth.currentUser!.isAnonymous != true) {
      final cred = await auth.signInAnonymously();
      // ignore: avoid_print
      print('>>> Signed in anonymously: uid=${cred.user?.uid}');
      return cred.user!;
    }
    // ignore: avoid_print
    print('>>> Using existing anon uid=${auth.currentUser?.uid}');
    return auth.currentUser!;
  }

  /// ينشئ/يحدّث جلسة السكرتير في secretary_sessions/{uid}
  /// القيم متوافقة مع القواعد (hasOnly([...])):
  /// doctorId, codeId, createdAt, expiresAt, secretaryUid[, status]
  Future<void> _createSecretarySession({
    required String doctorId,
    required String codeId,
    required DateTime expiresAt,
  }) async {
    final user = await _ensureAnonUser();
    final fs = FirebaseFirestore.instance;

    await fs.collection('secretary_sessions').doc(user.uid).set({
      'doctorId': doctorId,
      'codeId': codeId,
      'createdAt':
          FieldValue.serverTimestamp(), // يطابق request.time في القواعد
      'expiresAt': Timestamp.fromDate(expiresAt),
      'secretaryUid': user.uid,
      'status': 'active', // مسموح في القواعد (اختياري لكن مفيد)
    });

    // ignore: avoid_print
    print(
      '>>> secretary_sessions/${user.uid} written: doctorId=$doctorId codeId=$codeId exp=$expiresAt',
    );
  }

  /// (اختياري) تحديث user_roles/{uid} ليس مطلوبًا للقواعد لكنه مفيد مستقبلاً
  Future<void> _touchUserRoles(String uid, String doctorId) async {
    final rolesRef = FirebaseFirestore.instance
        .collection('user_roles')
        .doc(uid);
    await rolesRef.set({
      'secretaryOf': FieldValue.arrayUnion([doctorId]),
      // 'lastSecretaryLoginAt': FieldValue.serverTimestamp(), // اختياري
    }, SetOptions(merge: true));

    // ignore: avoid_print
    print('>>> user_roles/$uid updated: secretaryOf += $doctorId');
  }

  // -----------------------------
  // قراءة وثيقة الكود مباشرة (بدون Query)
  // -----------------------------

  /// يجلب وثيقة الكود من:
  /// doctors/{doctorId}/secretary_codes/{codeId}
  /// حيث codeId هو النص الذي أدخله السكريتير (مثلاً SEC-4FCLTN)
  /// ويعيد (codeId, expiresAt, activeOrStatusActive)؛
  /// يرمي استثناءً إذا الوثيقة غير موجودة/غير مفعّلة/منتهية.
  Future<({String codeId, DateTime? expiresAt})> _fetchCodeDocById({
    required String doctorId,
    required String enteredCode,
  }) async {
    final codeId = enteredCode.trim().toUpperCase(); // نوحّد الـ docId
    final ref = FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .collection('secretary_codes')
        .doc(codeId);

    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('الكود غير صحيح.');
    }

    final data = snap.data()!;
    final bool isActive =
        (data['active'] == true) || (data['status'] == 'active');
    if (!isActive) {
      throw StateError('الكود غير مفعّل.');
    }

    DateTime? expiresAt;
    final expiresAny = data['expiresAt'];
    if (expiresAny is Timestamp) {
      expiresAt = expiresAny.toDate();
      if (expiresAt.isBefore(DateTime.now())) {
        throw StateError('انتهت صلاحية الكود.');
      }
    } else {
      // في حال لا يوجد expiresAt، نعتبره بلا صلاحية انتهاء (مسموح بالقواعد إن سمحت به)
      expiresAt = null;
    }

    return (codeId: codeId, expiresAt: expiresAt);
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
      // (1) تحقّق الكود عبر الخدمة (لو عندك QR أو Endpoint يُرجع doctorId)
      final verifier = SecretaryCodeVerifier();
      final res = await verifier.verify(raw);

      if (!res.ok) {
        if (!mounted) return;
        setState(() => _error = res.reason ?? 'تعذّر التحقق من الكود');
        return;
      }

      // نتوقع من خدمة التحقق على الأقل doctorId
      final String? doctorId = res.doctorId;
      if (doctorId == null || doctorId.isEmpty) {
        if (!mounted) return;
        setState(() => _error = 'التحقق نجح لكن doctorId غير متوفر.');
        return;
      }

      // (2) جلب تفاصيل الكود بالوثيقة مباشرة (docId = code)
      // إذا الخدمة أعادت codeId/expiresAt، نستعملهم، وإلا نقرأ من Firestore
      String? codeId = (res.codeId ?? res.code)?.trim().toUpperCase();
      DateTime? expiresAt = res.expiresAt;

      if (codeId == null || codeId.isEmpty || expiresAt == null) {
        final fetched = await _fetchCodeDocById(
          doctorId: doctorId,
          enteredCode: raw,
        );
        codeId = fetched.codeId;
        expiresAt ??= fetched.expiresAt;
      }

      // إن لم يحدد الكود تاريخ انتهاء، نعطي صلاحية جلسة معقولة (مثلاً 8 ساعات)
      expiresAt ??= DateTime.now().add(const Duration(hours: 8));

      // Debug
      // ignore: avoid_print
      print(
        '>>> VERIFY OK. doctorId=$doctorId, codeId=$codeId, exp=$expiresAt',
      );

      // (3) تسجيل دخول (Anonymous) + إنشاء جلسة سكرتير
      final user = await _ensureAnonUser();

      await _createSecretarySession(
        doctorId: doctorId,
        codeId: codeId, // صار مضمونًا الآن
        expiresAt: expiresAt, // صار مضمونًا الآن
      );

      // (اختياري) تحديث user_roles
      try {
        await _touchUserRoles(user.uid, doctorId);
      } on FirebaseException catch (e) {
        debugPrint('FIRESTORE user_roles set error: ${e.code} ${e.message}');
        // لا نمنع المتابعة لو roles فشلت
      }

      // (4) افتح مساحة السكريتير
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SecretaryDashboardScreen(doctorId: doctorId),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH ERROR: ${e.code} ${e.message}');
      if (!mounted) return;
      String msg = 'تعذّر تسجيل الدخول. أعد المحاولة.';
      if (e.code == 'operation-not-allowed') {
        msg =
            'خيار تسجيل الدخول المجهول غير مفعّل.\nفعّل Anonymous من Firebase Console ثم أعد المحاولة.';
      } else if (e.code == 'network-request-failed') {
        msg = 'مشكلة في الاتصال بالشبكة. تحقّق من الإنترنت ثم أعد المحاولة.';
      }
      setState(() => _error = msg);
      return;
    } on FirebaseException catch (e) {
      debugPrint('FIRESTORE ERROR: ${e.code} ${e.message}');
      if (!mounted) return;
      String msg = 'تعذّر إتمام العملية. أعد المحاولة.';
      if (e.code == 'permission-denied') {
        msg =
            'تعذّر إنشاء جلسة السكريتير: صلاحيات غير كافية.\nتحقّق من قواعد secretary_sessions ثم أعد المحاولة.';
      }
      setState(() => _error = msg);
      return;
    } on StateError catch (e) {
      // أخطاء واضحة: كود غير موجود/غير مفعّل/منتهي الصلاحية
      if (!mounted) return;
      setState(() => _error = e.message);
      return;
    } catch (e, st) {
      debugPrint('SecretaryCode Generic ERROR: $e');
      debugPrint('STACK: $st');
      if (!mounted) return;
      setState(() => _error = 'تعذّر التحقق من الكود');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'أدخل كود السكريتير الذي زوّدك به الطبيب',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeCtrl,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'كود السكريتير',
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
                      color: Theme.of(context).colorScheme.error,
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
