// lib/features/secretary/ui/secretary_code_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:medical_booking/features/secretary/data/verify_secretary_code.dart';
import 'package:medical_booking/screens/secretary/secretary_dashboard_screen.dart';

class SecretaryCodeScreen extends StatefulWidget {
  const SecretaryCodeScreen({super.key});

  @override
  State<SecretaryCodeScreen> createState() => _SecretaryCodeScreenState();
}

class _SecretaryCodeScreenState extends State<SecretaryCodeScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ✅ التأكّد من وجود مستخدم (حتى لو مجهول)
  Future<User> _ensureUser() async {
    final auth = FirebaseAuth.instance;
    final cu = auth.currentUser;

    if (cu != null) return cu;
    final cred = await auth.signInAnonymously();
    return cred.user!;
  }

  // ✅ جلب الكود العام
  Future<({String doctorId, String codeId, DateTime? expiresAt})>
  _fetchPublicCode(String rawCode) async {
    final codeId = rawCode.trim().toUpperCase();
    final ref = FirebaseFirestore.instance
        .collection('secretary_codes_public')
        .doc(codeId);

    final snap = await ref.get();

    if (!snap.exists) {
      throw StateError("الكود غير صحيح.");
    }

    final data = snap.data()!;
    final bool active = data['active'] == true;

    if (!active) throw StateError("الكود غير مفعّل.");

    final doctorId = (data['doctorId'] ?? "").toString();
    if (doctorId.isEmpty) throw StateError("doctorId غير موجود.");

    DateTime? expiresAt;
    final any = data['expiresAt'];
    if (any is Timestamp) {
      expiresAt = any.toDate();
      if (expiresAt.isBefore(DateTime.now())) {
        throw StateError("انتهت صلاحية الكود.");
      }
    }

    return (doctorId: doctorId, codeId: codeId, expiresAt: expiresAt);
  }

  // ✅ إنشاء جلسة السكرتير
  Future<void> _createSecretarySession({
    required String uid,
    required String doctorId,
    required String codeId,
  }) async {
    final fs = FirebaseFirestore.instance;

    final sessionId = "${uid}_$doctorId";

    await fs.collection('secretary_sessions').doc(sessionId).set({
      "secretaryUid": uid,
      "doctorId": doctorId,
      "active": true,
      "startedAt": FieldValue.serverTimestamp(),
      "codeId": codeId,
    }, SetOptions(merge: true));
  }

  // ✅ عملية التحقق الشاملة
  Future<void> _handleVerify({String? overrideCode}) async {
    final t = AppLocalizations.of(context)!;

    final raw = (overrideCode ?? _codeCtrl.text).trim();

    if (raw.isEmpty) {
      setState(() => _error = t.enterCode);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _ensureUser();

      final verifier = SecretaryCodeVerifier();
      final res = await verifier.verify(raw, context);
      if (!res.ok) {
        setState(() => _error = res.reason ?? t.codeVerificationFailed);
        return;
      }

      final pub = await _fetchPublicCode(raw);
      final doctorId = pub.doctorId;
      final codeId = pub.codeId;

      await _createSecretarySession(
        uid: user.uid,
        doctorId: doctorId,
        codeId: codeId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SecretaryDashboardScreen(doctorId: doctorId),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = t.authFailed;

      if (e.code == 'operation-not-allowed') {
        msg = t.anonymousAuthNotEnabled;
      } else if (e.code == 'network-request-failed') {
        msg = t.networkError;
      }

      setState(() => _error = msg);
      return;
    } on FirebaseException catch (e) {
      final msg = e.code == 'permission-denied'
          ? t.permissionDeniedSessions
          : "${t.operationFailed} (${e.code})";

      setState(() => _error = msg);
      return;
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = t.codeVerificationFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.secretarySpace)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.secretaryEnterCodeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _codeCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t.secretaryCode,
                    hintText: t.secretaryCodeExample,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key_outlined),
                  ),
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() => _error = null);
                    }
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
                    label: Text(t.login),
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
