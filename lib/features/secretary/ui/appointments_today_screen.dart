import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// شاشة مواعيد اليوم.
/// - في فضاء السكريتير: مرّر doctorId + hideInnerHeader:true + (اختياري asSecretary:true)
/// - في وضع الطبيب: اترك asSecretary=false ومرّر doctorId إن كنت تستنتجه خارجيًا.
class AppointmentsTodayScreen extends StatefulWidget {
  final String doctorId;

  /// هل المستخدم الحالي سكريتير (لإظهار أزرار Check-in / No-show)؟
  final bool asSecretary;

  /// NEW: إخفاء الهيدر الداخلي (العنوان + السهم) عندما نكون داخل فضاء السكريتير
  final bool hideInnerHeader;

  const AppointmentsTodayScreen({
    super.key,
    required this.doctorId,
    this.asSecretary = true,
    this.hideInnerHeader = false, // الافتراضي لا نخفي، نُخفي من فضاء السكريتير
  });

  @override
  State<AppointmentsTodayScreen> createState() =>
      _AppointmentsTodayScreenState();
}

class _AppointmentsTodayScreenState extends State<AppointmentsTodayScreen> {
  late final DateTime _todayStart;
  late final DateTime _todayEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _todayAppointmentsStream() {
    // لو عندك dateTime مخزَّن Timestamp (موصى به)
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: _todayStart)
        .where('dateTime', isLessThanOrEqualTo: _todayEnd)
        .orderBy('dateTime')
        .snapshots();
  }

  Future<void> _updateStatus(String apptId, String status) async {
    await FirebaseFirestore.instance.collection('appointments').doc(apptId).update({
      'status': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'statusBy': {
        'role': widget.asSecretary ? 'secretary' : 'doctor',
        // uid يلتقط من Auth في سيرفيسك عادة؛ هنا نتركه اختياريًا لو تحب تضيفه من خارج
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❗ لا نعرض AppBar داخلي عندما نكون في فضاء السكريتير
      appBar: widget.hideInnerHeader
          ? null
          : AppBar(title: const Text('مواعيد اليوم')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _todayAppointmentsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('خطأ في تحميل مواعيد اليوم'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد مواعيد اليوم'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final ref = docs[i].reference;
              final d = docs[i].data();

              final patientName = (d['patientName'] ?? 'مريض').toString();
              final patientPhone = (d['patientPhone'] ?? '').toString();
              final status = (d['status'] ?? 'pending').toString();

              DateTime? dt;
              final dtAny = d['dateTime'];
              if (dtAny is Timestamp) dt = dtAny.toDate();

              final timeLabel = dt != null
                  ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}"
                  : (d['time'] ?? '--:--').toString();

              final Color statusColor = switch (status) {
                'confirmed' => Colors.green,
                'checked_in' => Colors.blue,
                'no_show' => Colors.deepOrange,
                'canceled' => Colors.red,
                _ => Colors.orange,
              };

              // السكريتير حصريًا: Check-in / No-show
              final canCheckIn = widget.asSecretary && status == 'confirmed';
              final canNoShow =
                  widget.asSecretary &&
                  (status == 'pending' ||
                      status == 'requested' ||
                      status == 'confirmed');

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(.15),
                    child: Icon(Icons.person, color: statusColor),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          patientName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "الوقت: $timeLabel • الهاتف: ${patientPhone.isEmpty ? 'غير متوفر' : patientPhone}",
                    ),
                  ),

                  // أزرار الإجراءات (للسكريتير فقط)
                  trailing: widget.asSecretary
                      ? Wrap(
                          spacing: 6,
                          children: [
                            if (canCheckIn)
                              _miniBtn(
                                label: 'حضور',
                                color: Colors.blue,
                                onTap: () async {
                                  try {
                                    await _updateStatus(ref.id, 'checked_in');
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم تسجيل الحضور'),
                                      ),
                                    );
                                  } on FirebaseException catch (e) {
                                    _showPermSnack(context, e);
                                  } catch (e) {
                                    _showError(context, e);
                                  }
                                },
                              ),
                            if (canNoShow)
                              _miniBtn(
                                label: 'لم يحضر',
                                color: Colors.deepOrange,
                                onTap: () async {
                                  try {
                                    await _updateStatus(ref.id, 'no_show');
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم وضع الحالة: لم يحضر'),
                                      ),
                                    );
                                  } on FirebaseException catch (e) {
                                    _showPermSnack(context, e);
                                  } catch (e) {
                                    _showError(context, e);
                                  }
                                },
                              ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(String s) {
    return switch (s) {
      'confirmed' => 'مؤكّد',
      'checked_in' => 'حاضر',
      'no_show' => 'لم يحضر',
      'canceled' => 'ملغى',
      'pending' => 'قيد الانتظار',
      'requested' => 'طلب حجز',
      _ => s,
    };
  }

  Widget _miniBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(10, 36),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  void _showPermSnack(BuildContext context, FirebaseException e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.code == 'permission-denied'
              ? 'صلاحيات غير كافية. تأكّد من قواعد Firestore وجلسة السكريتير.'
              : 'تعذّر تنفيذ العملية: ${e.code}',
        ),
      ),
    );
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('خطأ غير متوقع: $e')));
  }
}
