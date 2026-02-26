import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/doctor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final _doctorService = DoctorService();
  String? patientId;
  String? doctorId;
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
    doctorId = await _doctorService.getDoctorId();

    setState(() => loading = false);
  }

  Stream<List<Map<String, dynamic>>> _myAppointments() {
    if (patientId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime') // إن ظهرت رسالة index أنشئ Composite Index
        .snapshots()
        .map((snap) {
      final results = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        // تحويل Timestamp إلى DateTime (إن لزم)
        DateTime? dt;
        final raw = data['dateTime'];
        if (raw is Timestamp) {
          dt = raw.toDate();
        } else if (raw is DateTime) {
          dt = raw;
        } else if (raw is String) {
          dt = DateTime.tryParse(raw);
        }

        results.add({
          'id': doc.id,
          'doctorId': (data['doctorId'] ?? '').toString(),
          'doctorName': (data['doctorName'] ?? '').toString(),
          'doctorSpecialty': (data['doctorSpecialty'] ?? '').toString(),
          'dateTime': dt,
          'status': (data['status'] ?? 'pending').toString(),
        });
      }

      return results;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (patientId == null) {
      return const Scaffold(
        body: Center(
          child: Text('لم يتم تسجيل الدخول'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('مواعيدي')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _myAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('تعذّر تحميل المواعيد. يرجى المحاولة لاحقًا.'),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد مواعيد بعد.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = items[i];

              // العنوان: اسم الطبيب إن وُجد، وإلا doctorId
              final String doctorName = a['doctorName'] ?? '';
              final String doctorSpec = a['doctorSpecialty'] ?? '';
              final String fallbackTitle = 'طبيب: ${a['doctorId']}';
              final String title = (doctorName.isNotEmpty ? doctorName : fallbackTitle);

              // التاريخ والوقت
              final DateTime? dt = a['dateTime'] as DateTime?;
              final String dateStr = dt == null
                  ? '—'
                  : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              final String timeStr = dt == null
                  ? '—'
                  : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

              // الحالة + لون الشارة
              final String status = a['status'] ?? 'pending';
              Color statusColor;
              String statusLabelAr;
              switch (status) {
                case 'confirmed':
                  statusColor = Colors.green;
                  statusLabelAr = 'مؤكّد';
                  break;
                case 'canceled':
                  statusColor = Colors.red;
                  statusLabelAr = 'ملغى';
                  break;
                default:
                  statusColor = Colors.orange;
                  statusLabelAr = 'قيد الانتظار';
              }

              final String subtitle = doctorSpec.isNotEmpty
                  ? '$dateStr  •  $timeStr الاختصاص: $doctorSpec'
                  : '$dateStr  •  $timeStr';

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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                if (doctorSpec.isNotEmpty)
                                  Text('الاختصاص: $doctorSpec'),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withOpacity(0.5)),
                                ),
                                child: Text(
                                  statusLabelAr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'cancel' && a['id'] != null) {
                                    final appointmentRef = FirebaseFirestore.instance
                                        .collection('appointments')
                                        .doc(a['id']);

                                    await FirebaseFirestore.instance.runTransaction((t) async {
                                      final apptSnap = await t.get(appointmentRef);
                                      if (!apptSnap.exists) return;

                                      final data = apptSnap.data()!;
                                      final slotId = data['slotId'];

                                      // إلغاء الموعد
                                      t.update(appointmentRef, {'status': 'canceled'});

                                      // تحرير التوقيت عند الطبيب
                                      if (slotId != null) {
                                        final slotRef = FirebaseFirestore.instance
                                            .collection('doctor_slots')
                                            .doc(slotId);

                                        t.update(slotRef, {'taken': false});
                                      }
                                    });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم إلغاء الموعد وأصبح التوقيت متاحًا'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'cancel',
                                    child: Text('إلغاء الموعد'),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
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
