import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:medical_booking/services/doctor_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final _doctorService = DoctorService();
  String? patientId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  Future<void> _initUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    patientId = user.uid;
    setState(() => loading = false);
  }

  Stream<List<Map<String, dynamic>>> _myAppointments() {
    if (patientId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snap) {
          final results = <Map<String, dynamic>>[];

          for (final doc in snap.docs) {
            final data = doc.data();

            DateTime? dt;
            if (data['dateTime'] != null && data['dateTime'] is Timestamp) {
              dt = (data['dateTime'] as Timestamp).toDate();
            }

            results.add({
              'id': doc.id,
              'doctorId': data['doctorId'] ?? '',
              'doctorName': data['doctorName'] ?? '',
              'doctorSpecialty': data['doctorSpecialty'] ?? '',
              'dateTime': dt,
              'status': data['status'] ?? 'pending',
            });
          }

          return results;
        });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (patientId == null) {
      return Scaffold(body: Center(child: Text(t.notLoggedIn)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.myAppointments)),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _myAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(t.failedToLoadAppointments));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(child: Text(t.noAppointmentsYet));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = items[i];

              final String doctorName = a['doctorName'];
              final String specialty = a['doctorSpecialty'];

              final title = doctorName.isNotEmpty
                  ? doctorName
                  : "${t.doctor}: ${a['doctorId']}";

              final DateTime? dt = a['dateTime'];
              final String dateStr = dt == null
                  ? '—'
                  : "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

              final String timeStr = dt == null
                  ? '—'
                  : "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

              final String status = a['status'];
              Color statusColor;
              String statusLabel;

              switch (status) {
                case 'confirmed':
                  statusColor = Colors.green;
                  statusLabel = t.statusConfirmed;
                  break;
                case 'canceled':
                  statusColor = Colors.red;
                  statusLabel = t.statusCanceled;
                  break;
                default:
                  statusColor = Colors.orange;
                  statusLabel = t.statusPending;
              }

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),

                                if (specialty.isNotEmpty)
                                  Text("${t.specialty}: $specialty"),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 6),
                          Text(dateStr),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 6),
                          Text(timeStr),
                        ],
                      ),
                      const SizedBox(height: 10),

                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          try {
                            if (v == 'delete' && a['id'] != null) {
                              await FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(a['id'])
                                  .delete();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.appointmentDeleted)),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t.operationFailed)),
                              );
                            }
                          }
                        },

                        itemBuilder: (_) => [
                          // ✅ يظهر فقط إذا كان الموعد ملغى
                          if (status == 'canceled')
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t.deleteAppointment,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        icon: const Icon(Icons.more_vert),
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
