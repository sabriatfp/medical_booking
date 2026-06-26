import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      _markAllAsSeen();
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('reports')
        .where('senderId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.myReports)),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openSendDialog(context);
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(child: Text(t.noReports));
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final d = docs[i].data();

              final typeKey = (d['type'] ?? '').toString();

              late String type;

              switch (typeKey) {
                case 'bug':
                  type = t.bug;
                  break;
                case 'complaint':
                  type = t.complaint;
                  break;
                case 'payment':
                  type = t.payment;
                  break;
                default:
                  type = typeKey;
              }
              final msg = d['message'] ?? '';
              final status = d['status'] ?? 'new';
              final ts = d['createdAt'];
              final reply = d['reply'] ?? '';

              final hasReply = reply.isNotEmpty;

              DateTime? dt;
              if (ts is Timestamp) {
                dt = ts.toDate();
              }

              final color = status == 'processed'
                  ? Colors.green
                  : Colors.orange;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                color: Color.fromARGB(255, 236, 238, 226),

                // : null, // ✅ highlight
                child: ListTile(
                  onTap: () async {
                    if (reply.isNotEmpty && d['replySeen'] != true) {
                      await docs[i].reference.update({'replySeen': true});
                    }
                  },

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),

                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(Icons.report, color: Colors.teal),
                  ),

                  title: Text(
                    type,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ✅ الحالة أولاً
                      Text(
                        status == 'processed' ? t.processed : t.newReport,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      /// ✅ الرسالة
                      if (msg.isNotEmpty)
                        Text(msg, maxLines: 4, overflow: TextOverflow.fade),

                      /// ✅ التاريخ
                      if (dt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(dt),
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color.fromARGB(255, 28, 29, 28),
                          ),
                        ),
                      ],

                      /// ✅ الرد من admin
                      if (hasReply)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ✅ label
                              Text(
                                t.adminReply,

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.reply,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      reply,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Future<void> _markAllAsSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('reports')
        .where('senderId', isEqualTo: user.uid)
        .where('replySeen', isEqualTo: false)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.update({'replySeen': true});
    }

    print("✅ ALL REPORTS MARKED AS SEEN");
  }
  // ================= SEND REPORT =================

  void _openSendDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String type = 'bug';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// ✅ TITLE (أصغر)
                      Text(
                        t.sendReport,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ✅ TYPE DROPDOWN (FULL WIDTH)
                      DropdownButtonFormField<String>(
                        value: type,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'bug', child: Text(t.bug)),
                          DropdownMenuItem(
                            value: 'complaint',
                            child: Text(t.complaint),
                          ),
                          DropdownMenuItem(
                            value: 'payment',
                            child: Text(t.payment), // ✅ بدل suggestion
                          ),
                        ],
                        onChanged: (v) => setState(() => type = v!),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ✅ TEXT AREA كبير
                      TextField(
                        controller: controller,
                        minLines: 6,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText: t.describeProblem,
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// ✅ BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(t.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _sendReport(context, type, controller.text);
                              Navigator.pop(context);
                            },
                            child: Text(t.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendReport(
    BuildContext context,
    String type,
    String message,
  ) async {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || message.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidInput)));
      return;
    }

    try {
      /// ✅ 1. نجيب user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final doctorId = userDoc.data()?['doctorId'];

      String name = 'Unknown';

      /// ✅ 2. نجيب doctor
      if (doctorId != null) {
        final doctorDoc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .get();

        if (doctorDoc.exists) {
          name = (doctorDoc.data()?['name'] ?? 'Unknown').toString();
        }
      }

      /// ✅ DEBUG (اختياري)
      print("✅ REPORT NAME = $name");

      /// ✅ 3. إرسال التقرير
      await FirebaseFirestore.instance.collection('reports').add({
        'type': type,
        'message': message.trim(),
        'senderId': user.uid,
        'senderName': name,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.reportSentSuccessfully)));
    } catch (e) {
      print("❌ ERROR SEND REPORT: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error sending report")));
    }
  }
}
