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

  Future<bool> _confirmCancelDialog(BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.cancelAppointment),
        content: Text(t.confirmCancelAppointment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.yesCancel),
          ),
        ],
      ),
    );

    return result == true;
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
              'slotId': data['slotId'], // ✅ مهم جدًا
              'patientUpdate': data['patientUpdate'] == true,
            });
          }

          return results;
        });
  }

  Future<void> _clearPatientUpdates() async {
    if (patientId == null) return;

    final fs = FirebaseFirestore.instance;

    final snap = await fs
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .where('patientUpdate', isEqualTo: true)
        .get();

    final batch = fs.batch();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'patientUpdate': false});
    }

    await batch.commit();
  }

  @override
  void dispose() {
    _clearPatientUpdates(); // ✅ هنا يتم تنظيف الإشعارات
    super.dispose();
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
              final bool hasUpdate = a['patientUpdate'] == true;
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

              return Stack(
                children: [
                  Card(
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

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (status == 'pending' || status == 'confirmed')
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.orange,
                                  ),
                                  label: Text(
                                    t.cancelAppointment,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final confirmed =
                                        await _confirmCancelDialog(context);
                                    if (!confirmed) return;

                                    final slotId = a['slotId'];
                                    if (slotId == null || slotId.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(t.operationFailed),
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      await _doctorService.cancelAppointment(
                                        appointmentId: a['id'],
                                        slotId: slotId,
                                      );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              t.appointmentCanceled,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(t.operationFailed),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),

                              if (status == 'canceled')
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  label: Text(
                                    t.deleteAppointment,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('appointments')
                                          .doc(a['id'])
                                          .delete();

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(t.appointmentDeleted),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(t.operationFailed),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// ✅ النقطة الحمراء
                  if (hasUpdate)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
