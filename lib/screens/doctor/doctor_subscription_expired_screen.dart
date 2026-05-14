import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorSubscriptionExpiredScreen extends StatefulWidget {
  const DoctorSubscriptionExpiredScreen({super.key});

  @override
  State<DoctorSubscriptionExpiredScreen> createState() =>
      _DoctorSubscriptionExpiredScreenState();
}

class _DoctorSubscriptionExpiredScreenState
    extends State<DoctorSubscriptionExpiredScreen> {
  bool _loading = false;
  bool _alreadyRequested = false;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _sendRequest(AppLocalizations t) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;

    try {
      final userSnap = await db
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      final data = userSnap.data();
      if (data == null) throw Exception("User data missing");

      final doctorId = data['doctorId'];
      if (doctorId == null || doctorId.toString().isEmpty) {
        throw Exception("DoctorId missing");
      }

      // ✅ إنشاء الطلب مباشرة (بدون Query)
      await db.collection('subscription_requests').add({
        'doctorUid': user.uid,
        'doctorId': doctorId,
        'doctorName': data['name'] ?? '',
        'email': data['email'] ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': null,
        'processedBy': null,
      });

      setState(() {
        _alreadyRequested = true;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.subscriptionRequestSent)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${t.actionFailed}: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final DateTime? subscriptionEnd =
        ModalRoute.of(context)?.settings.arguments as DateTime?;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.subscription),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_clock,
                      size: 64,
                      color: Colors.redAccent,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      t.subscriptionExpired,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      t.subscriptionExpiredMessage,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    if (subscriptionEnd != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          "${t.subscriptionEndedAt}: ${DateFormat('yyyy-MM-dd').format(subscriptionEnd)}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _alreadyRequested
                              ? t.subscriptionRequestAlreadySent
                              : t.requestSubscriptionRenewal,
                        ),
                        onPressed: (_loading || _alreadyRequested)
                            ? null
                            : () => _sendRequest(t),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(onPressed: _logout, child: Text(t.logout)),
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
