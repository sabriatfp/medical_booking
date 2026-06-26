// lib/screens/doctor/appointments_today_screen.dart
import 'package:medical_booking/services/doctor_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

class AppointmentsTodayScreen extends StatefulWidget {
  final String doctorId;
  final bool asSecretary;
  final bool hideInnerHeader;

  const AppointmentsTodayScreen({
    super.key,
    required this.doctorId,
    this.asSecretary = true,
    this.hideInnerHeader = false,
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
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: _todayStart)
        .where('dateTime', isLessThanOrEqualTo: _todayEnd)
        .orderBy('dateTime')
        .snapshots();
  }

  Future<void> _updateStatus(String apptId, String status) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(apptId)
        .update({
          'status': status,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
          'statusBy': {'role': widget.asSecretary ? 'secretary' : 'doctor'},
        });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: widget.hideInnerHeader
          ? null
          : AppBar(title: Text(t.todayAppointments)),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _todayAppointmentsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text(t.loadTodayError));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text(t.noAppointmentsToday));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),

            itemBuilder: (context, i) {
              final ref = docs[i].reference;
              final d = docs[i].data();

              final patientName = (d['patientName'] ?? t.patient).toString();
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

              final canCheckIn = widget.asSecretary && status == 'confirmed';
              final canNoShow =
                  widget.asSecretary &&
                  (status == 'pending' ||
                      status == 'requested' ||
                      status == 'confirmed');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),

                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================
                      // ✅ السطر 1: الاسم
                      // =========================
                      Text(
                        patientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // =========================
                      // ✅ السطر 2: الوقت + الأزرار
                      // =========================
                      Row(
                        children: [
                          // ✅ الوقت (يسار في FR / يمين في AR تلقائيًا)
                          Expanded(
                            child: Text(
                              "${t.time}: $timeLabel",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),

                          // ✅ الأزرار (على اليمين)
                          if (widget.asSecretary)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canCheckIn)
                                  _miniBtn(
                                    label: t.checkIn,
                                    color: Colors.blue,
                                    onTap: () async {
                                      final amount = await _askPaidAmount(
                                        context,
                                      );
                                      if (amount == null) return;

                                      try {
                                        await DoctorService()
                                            .checkInAppointment(
                                              appointmentId: ref.id,
                                              doctorId: widget.doctorId,
                                              patientId: d['patientId'],
                                              amount: amount,
                                            );

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(t.checkedIn)),
                                        );
                                      } catch (e) {
                                        _showError(context, e, t);
                                      }
                                    },
                                  ),

                                const SizedBox(width: 4),

                                if (canNoShow)
                                  _miniBtn(
                                    label: t.noShow,
                                    color: Colors.deepOrange,
                                    onTap: () async {
                                      try {
                                        await _updateStatus(ref.id, 'no_show');

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(t.noShowSet)),
                                        );
                                      } catch (e) {
                                        _showError(context, e, t);
                                      }
                                    },
                                  ),
                              ],
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // =========================
                      // ✅ السطر 3: الهاتف + الحالة
                      // =========================
                      Row(
                        children: [
                          // ✅ الهاتف
                          Expanded(
                            child: Text(
                              "${t.phone}: ${patientPhone.isEmpty ? t.notAvailable : patientPhone}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),

                          // ✅ الحالة (تحت الأزرار)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _statusLabel(status, t),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
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

  Future<double?> _askPaidAmount(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.enterPaidAmount),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: t.amountHint,
            suffixText: t.currency,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value == null || value <= 0) return;
              Navigator.pop(ctx, value);
            },
            child: Text(t.confirm),
          ),
        ],
      ),
    );

    return result;
  }

  String _statusLabel(String s, AppLocalizations t) {
    return switch (s) {
      'confirmed' => t.statusConfirmed,
      'checked_in' => t.checkedInShort,
      'no_show' => t.noShow,
      'canceled' => t.statusCanceled,
      'pending' => t.statusPending,
      'requested' => t.requested,
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
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size(10, 36),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  void _showError(BuildContext context, Object e, AppLocalizations t) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${t.unexpectedError}: $e")));
  }
}
