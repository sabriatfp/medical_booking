import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import '../../services/doctor_service.dart';
import 'package:intl/intl.dart';
import 'package:medical_booking/screens/doctor/appointment_details_screen.dart';

enum DocApptFilter { all, pending, confirmed, canceled }

class DoctorDashboardScreen extends StatefulWidget {
  final String doctorId;
  final bool asSecretary;
  final bool hideInnerHeader;

  const DoctorDashboardScreen({
    super.key,
    required this.doctorId,
    this.asSecretary = false,
    this.hideInnerHeader = false,
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  DocApptFilter _filter = DocApptFilter.all;
  bool _loading = true;

  Timer? _waitTimer;
  bool _streamWaitingTooLong = false;

  @override
  void initState() {
    super.initState();

    // ✅ doctorId جاهز 100% — لا نحتاج أي getDoctorId()
    _loading = false;
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  String? _statusFromFilter() {
    switch (_filter) {
      case DocApptFilter.pending:
        return 'pending';
      case DocApptFilter.confirmed:
        return 'confirmed';
      case DocApptFilter.canceled:
        return 'canceled';
      case DocApptFilter.all:
      default:
        return null;
    }
  }

  // ====== الاتصال ======
  Future<void> _callNumber(String phone) async {
    final t = AppLocalizations.of(context)!;

    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.phoneUnavailable)));
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone.trim());

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.callFailed)));
    }
  }

  // ========== واجهة البناء ==========
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ doctorId جاهز لأن الشاشة لا تُفتح إلا بوجوده
    final doctorId = widget.doctorId;
    final currentStatus = _statusFromFilter();

    return WillPopScope(
      onWillPop: () async {
        await _clearDoctorUpdates(); // ✅ هنا
        return true;
      },
      child: Scaffold(
        appBar: widget.hideInnerHeader
            ? null
            : AppBar(title: Text(t.doctorDashboard)),

        body: Column(
          children: [
            _filterChips(),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: DoctorService().appointmentsStream(
                  doctorId,
                  currentStatus,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    _startWaitTimer();
                  } else {
                    _cancelWaitTimer();
                  }

                  if (snapshot.hasError) {
                    return _centerMessage(t.errorLoadingAppointments);
                  }

                  if (!snapshot.hasData) {
                    return _waitingView(t);
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return _centerMessage(t.noAppointments);
                  }
                  docs.sort((a, b) {
                    final aNew = a.data()['doctorUpdate'] == true ? 1 : 0;
                    final bNew = b.data()['doctorUpdate'] == true ? 1 : 0;
                    return bNew.compareTo(aNew); // ✅ الجديد فوق
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i].data();
                      final String? slotId = d['slotId'] as String?;

                      DateTime? dt;
                      if (d['dateTime'] is Timestamp) {
                        dt = (d['dateTime'] as Timestamp).toDate();
                      }
                      final DateTime todayStart = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      );

                      // ✅ true إذا الموعد أمس أو قبل
                      final bool isBeforeToday =
                          dt != null && dt.isBefore(todayStart);

                      final patientName = (d['patientName'] ?? '').toString();
                      final patientPhone = (d['patientPhone'] ?? '').toString();
                      final status = (d['status'] ?? 'pending').toString();

                      final Color statusColor = isBeforeToday
                          ? Colors.grey
                          : status == 'confirmed'
                          ? Colors.green
                          : status == 'canceled'
                          ? Colors.red
                          : Colors.orange;

                      final isPending =
                          status == 'pending' || status == 'requested';
                      final isCancelable = status != 'canceled';

                      return Stack(
                        children: [
                          Card(
                            color: (isBeforeToday
                                ? Colors.grey.shade100
                                : null),

                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // =========================
                                  // ✅ السطر 1: اسم المريض
                                  // =========================
                                  Text(
                                    patientName.isEmpty
                                        ? t.patient
                                        : patientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isBeforeToday ? Colors.grey : null,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // =========================
                                  // ✅ السطر 2: الوقت + الأزرار
                                  // =========================
                                  Row(
                                    children: [
                                      // ✅ يسار: التاريخ
                                      Expanded(
                                        child: Text(
                                          dt != null
                                              ? DateFormat(
                                                  'yyyy-MM-dd HH:mm',
                                                ).format(dt)
                                              : t.notAvailable,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),

                                      // ✅ يمين: edit + menu
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AppointmentDetailsScreen(
                                                        data: d,
                                                        appointmentId:
                                                            docs[i].id,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),

                                          PopupMenuButton<String>(
                                            onSelected: (v) async {
                                              try {
                                                if (v == 'confirm') {
                                                  if (isBeforeToday) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          t.cannotConfirmPastAppointment,
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                        'appointments',
                                                      )
                                                      .doc(docs[i].id)
                                                      .update({
                                                        'status': 'confirmed',
                                                        'patientUpdate': true,
                                                        'updatedAt':
                                                            FieldValue.serverTimestamp(),
                                                      });
                                                } else if (v == 'cancel') {
                                                  if (slotId == null ||
                                                      slotId.isEmpty)
                                                    return;

                                                  await DoctorService()
                                                      .cancelAppointment(
                                                        appointmentId:
                                                            docs[i].id,
                                                        slotId: slotId,
                                                      );
                                                } else if (v == 'delete') {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                        'appointments',
                                                      )
                                                      .doc(docs[i].id)
                                                      .delete();
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      t.operationFailed,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            itemBuilder: (_) => [
                                              if (isPending && !isBeforeToday)
                                                PopupMenuItem(
                                                  value: 'confirm',
                                                  child: Text(
                                                    t.confirmAppointment,
                                                  ),
                                                ),
                                              if (isCancelable)
                                                PopupMenuItem(
                                                  value: 'cancel',
                                                  child: Text(
                                                    t.cancelAppointment,
                                                  ),
                                                ),
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
                                                        style: const TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
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
                                      // ✅ الهاتف يسار
                                      Expanded(
                                        child: Text(
                                          "${t.phone}: ${patientPhone.isEmpty ? t.notAvailable : patientPhone}",
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),

                                      // ✅ الحالة يمين
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          status == 'confirmed'
                                              ? t.statusConfirmed
                                              : status == 'canceled'
                                              ? t.statusCanceled
                                              : t.statusPending,
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
                          ),

                          // ✅ 🔴 نقطة الإشعار
                          if (d['doctorUpdate'] == true)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== واجهات مساعدة ==========

  Widget _centerMessage(String message) {
    return Center(child: Text(message));
  }

  Widget _waitingView(AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            _streamWaitingTooLong ? t.loadingTakingLong : t.loadingAppointments,
          ),
        ],
      ),
    );
  }

  // ========== الفلاتر ==========

  Widget _filterChips() {
    final t = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 8),

          _chip(t.all, DocApptFilter.all),
          _chip(t.statusPending, DocApptFilter.pending),
          _chip(t.statusConfirmed, DocApptFilter.confirmed),
          _chip(t.statusCanceled, DocApptFilter.canceled),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _chip(String label, DocApptFilter value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: ChoiceChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12), // ✅ تصغير الخط
        ),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),

        // ✅ تصغير الحجم
        visualDensity: VisualDensity.compact,

        // ✅ تقليل padding الداخلي
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }

  // ========== مؤقت الانتظار ==========
  void _startWaitTimer() {
    if (_waitTimer != null) return;

    _streamWaitingTooLong = false;

    _waitTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() => _streamWaitingTooLong = true);
    });
  }

  void _cancelWaitTimer() {
    if (_waitTimer != null) {
      _waitTimer!.cancel();
      _waitTimer = null;
    }
  }

  Future<void> _clearDoctorUpdates() async {
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('doctorUpdate', isEqualTo: true)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.update({"doctorUpdate": false});
    }
  }
}
