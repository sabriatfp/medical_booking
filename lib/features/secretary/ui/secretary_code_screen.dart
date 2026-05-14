// lib/features/secretary/ui/secretary_code_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:medical_booking/screens/login_screen.dart';
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

  /* ============================= */
  /* AUTH (Anonymous)              */
  /* ============================= */

  Future<User> _ensureUser() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return auth.currentUser!;
    }
    final cred = await auth.signInAnonymously();
    return cred.user!;
  }

  /* ============================= */
  /* VERIFY CODE (PUBLIC)          */
  /* ============================= */

  Future<({String doctorId, String codeId})> _verifyCode(String rawCode) async {
    final db = FirebaseFirestore.instance;
    final codeId = rawCode.trim().toUpperCase();

    final doc = await db.collection('secretary_codes_public').doc(codeId).get();

    if (!doc.exists) {
      throw StateError(AppLocalizations.of(context)!.codeNotValid);
    }

    final data = doc.data()!;

    if (data['active'] != true) {
      throw StateError(AppLocalizations.of(context)!.codeInactive);
    }

    final doctorId = (data['doctorId'] ?? '').toString();
    if (doctorId.isEmpty) {
      throw StateError(AppLocalizations.of(context)!.invalidCodeFormat);
    }

    final Timestamp? expiresTs = data['expiresAt'] as Timestamp?;
    if (expiresTs != null && expiresTs.toDate().isBefore(DateTime.now())) {
      throw StateError(AppLocalizations.of(context)!.codeExpired);
    }

    return (doctorId: doctorId, codeId: codeId);
  }

  /* ============================= */
  /* ENSURE SECRETARY DOCUMENT     */
  /* ============================= */

  Future<void> _ensureSecretaryDoc({
    required String uid,
    required String doctorId,
    required String codeId,
  }) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('secretaries').doc(uid);

    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'uid': uid,
      'doctorId': doctorId,
      'codeUsed': codeId,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* ============================= */
  /* CREATE SESSION (AUDIT)        */
  /* ============================= */

  Future<void> _createSession({
    required String uid,
    required String doctorId,
    required String codeId,
  }) async {
    final db = FirebaseFirestore.instance;

    await db.collection('secretary_sessions').add({
      'secretaryUid': uid,
      'doctorId': doctorId,
      'codeId': codeId,
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  /* ============================= */
  /* UPDATE USER (PERMISSIONS)     */
  /* ============================= */

  Future<void> _activateSecretaryRole({
    required String uid,
    required String doctorId,
  }) async {
    final db = FirebaseFirestore.instance;

    await db.collection('users').doc(uid).set({
      'role': 'secretary',
      'activeSecretaryDoctorId': doctorId,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /* ============================= */
  /* MAIN FLOW                     */
  /* ============================= */

  Future<void> _handleVerify() async {
    final raw = _codeCtrl.text.trim().toUpperCase();
    final t = AppLocalizations.of(context)!;

    if (raw.isEmpty) {
      setState(() => _error = t.enterCode);
      return;
    }

    if (!raw.startsWith('SEC-') || raw.length < 8) {
      setState(() => _error = t.invalidCodeFormat);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _ensureUser();
      final result = await _verifyCode(raw);

      await _ensureSecretaryDoc(
        uid: user.uid,
        doctorId: result.doctorId,
        codeId: result.codeId,
      );

      await _createSession(
        uid: user.uid,
        doctorId: result.doctorId,
        codeId: result.codeId,
      );

      await _activateSecretaryRole(uid: user.uid, doctorId: result.doctorId);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SecretaryDashboardScreen(doctorId: result.doctorId),
        ),
        (_) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.code == 'permission-denied'
            ? t.noPermission
            : '${t.connectionError} (${e.code})',
      );
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = t.unexpectedError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ============================= */
  /* UI                            */
  /* ============================= */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        title: Text(t.secretarySpace),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.enterSecretaryCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t.secretaryCode,
                    hintText: 'SEC-XXXXXX',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                  ),
                  onSubmitted: (_) => _handleVerify(),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: _loading ? null : _handleVerify,
                    child: _loading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Text(t.login),
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
