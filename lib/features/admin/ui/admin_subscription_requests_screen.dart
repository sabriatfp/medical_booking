import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'admin_subscriptions_screen.dart';

class AdminSubscriptionRequestsScreen extends StatelessWidget {
  const AdminSubscriptionRequestsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestsStream() {
    return FirebaseFirestore.instance
        .collection('subscription_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markAsProcessed(BuildContext context, String requestId) async {
    await FirebaseFirestore.instance
        .collection('subscription_requests')
        .doc(requestId)
        .update({
          'status': 'processed',
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': 'admin',
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Request processed')));
  }

  Future<void> _rejectRequest(BuildContext context, String requestId) async {
    await FirebaseFirestore.instance
        .collection('subscription_requests')
        .doc(requestId)
        .update({
          'status': 'rejected',
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': 'admin',
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('❌ Request rejected')));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.subscriptionRequests)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _requestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${t.errorLoading}: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                t.noSubscriptionRequests,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final doctorName = (data['doctorName'] ?? '').toString();
              final email = (data['email'] ?? '').toString();
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName.isNotEmpty ? doctorName : t.unknownDoctor,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),

                      if (createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${t.requestDate}: '
                            '${createdAt.toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: Text(t.activate),
                              onPressed: () async {
                                // ✅ نغلق الطلب (اختياري: يمكنك تأجيله)

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminSubscriptionsScreen(),
                                    settings: RouteSettings(
                                      arguments: {
                                        'doctorUid': data['doctorUid'],
                                        'doctorId': data['doctorId'],
                                        'doctorName': data['doctorName'],
                                        'requestId': doc.id, // ✅ مهم جدًا
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close),
                              label: Text(t.reject),
                              onPressed: () async {
                                await _rejectRequest(context, doc.id);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
