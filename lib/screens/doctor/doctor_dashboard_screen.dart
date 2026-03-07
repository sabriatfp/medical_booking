import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/doctor_service.dart';

enum DocApptFilter { all, pending, confirmed, canceled }

class DoctorDashboardScreen extends StatefulWidget {
  /// في وضع الطبيب: اتركها null وسيتم استنتاج doctorId من الحساب
  /// في وضع السكرتير: مرّر doctorId صراحة + asSecretary: true
  final String? doctorId;
  final bool asSecretary;

  /// NEW: إخفاء الهيدر الداخلي (العنوان + السهم) داخل فضاء السكريتير
  final bool hideInnerHeader;

  const DoctorDashboardScreen({
    super.key,
    this.doctorId,
    this.asSecretary = false,
    this.hideInnerHeader = false, // الافتراضي: لا نخفي
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DoctorService _doctorService = DoctorService();
  DocApptFilter _filter = DocApptFilter.all;

  String? _resolvedDoctorId; // الناتج النهائي الذي سنستخدمه
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveDoctorId();
  }

  Future<void> _resolveDoctorId() async {
    try {
      if (widget.doctorId != null && widget.doctorId!.isNotEmpty) {
        _resolvedDoctorId = widget.doctorId;
      } else {
        _resolvedDoctorId = await _doctorService.getDoctorId();
      }
      if (_resolvedDoctorId == null || _resolvedDoctorId!.isEmpty) {
        _error = 'لم يتم ربط الحساب بطبيب';
      }
    } catch (_) {
      _error = 'خطأ أثناء تحديد الطبيب';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  Future<void> _callNumber(String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        // ❗️لا نعرض AppBar داخلي عندما نكون في فضاء السكريتير
        appBar: widget.hideInnerHeader ? null : AppBar(title: _appBarTitle()),
        body: Center(child: Text(_error!)),
      );
    }

    final doctorId = _resolvedDoctorId!;
    return Scaffold(
      // ❗️لا نعرض AppBar داخلي عندما نكون في فضاء السكريتير (AppBar الرئيسي موجود في سكرتير داشبورد)
      appBar: widget.hideInnerHeader ? null : AppBar(title: _appBarTitle()),
      body: Column(
        children: [
          _filterChips(),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _doctorService.appointmentsStream(
                doctorId,
                _statusFromFilter(),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('خطأ في تحميل المواعيد'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد مواعيد'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();

                    // التاريخ/الوقت
                    DateTime? dt;
                    final dtAny = d['dateTime'];
                    if (dtAny is Timestamp) {
                      dt = dtAny.toDate();
                    }

                    final patientName = (d['patientName'] ?? '').toString();
                    final patientPhone = (d['patientPhone'] ?? '').toString();
                    final status = (d['status'] ?? 'pending').toString();

                    final Color statusColor = status == 'confirmed'
                        ? Colors.green
                        : status == 'canceled'
                        ? Colors.red
                        : Colors.orange;

                    // ✅ قرارات الواجهة: ماذا نعرض من خيارات حسب الحالة الحالية؟
                    final bool canConfirm =
                        status == 'pending' || status == 'requested';
                    final bool canCancel =
                        status == 'pending' ||
                        status == 'requested' ||
                        status == 'confirmed';

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: const Icon(Icons.calendar_month),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                patientName.isEmpty ? "مريض" : patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status == 'confirmed'
                                    ? 'مؤكّد'
                                    : status == 'canceled'
                                    ? 'ملغى'
                                    : 'قيد الانتظار',
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            (dt != null)
                                ? "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  "
                                      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}\n"
                                      "الهاتف: ${patientPhone.isEmpty ? 'غير متوفر' : patientPhone}"
                                : "الوقت: غير محدّد\n"
                                      "الهاتف: ${patientPhone.isEmpty ? 'غير متوفر' : patientPhone}",
                          ),
                        ),
                        isThreeLine: true,

                        // قائمة الإجراءات
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            try {
                              if (v == 'confirm') {
                                await _doctorService.updateAppointmentStatus(
                                  docs[i].id,
                                  'confirmed',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تأكيد الموعد'),
                                    ),
                                  );
                                }
                              } else if (v == 'cancel') {
                                await _doctorService.updateAppointmentStatus(
                                  docs[i].id,
                                  'canceled',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إلغاء الموعد'),
                                    ),
                                  );
                                }
                              }
                            } on FirebaseException catch (e) {
                              debugPrint(
                                'APPT UPDATE ERROR: ${e.code} ${e.message}',
                              );
                              if (mounted) {
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
                            } catch (e) {
                              debugPrint('APPT UPDATE ERROR: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('خطأ غير متوقع.'),
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (_) {
                            // ✅ نفس الخيارات للطبيب والسكرتير، مع إخفاء ما لا ينطبق على الحالة
                            final items = <PopupMenuEntry<String>>[];
                            if (canConfirm) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'confirm',
                                  child: Text('تأكيد الموعد'),
                                ),
                              );
                            }
                            if (canCancel) {
                              items.add(
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Text('إلغاء الموعد'),
                                ),
                              );
                            }
                            if (items.isEmpty) {
                              items.add(
                                const PopupMenuItem(
                                  enabled: false,
                                  child: Text('لا توجد إجراءات متاحة'),
                                ),
                              );
                            }
                            return items;
                          },
                          icon: const Icon(Icons.more_vert),
                        ),

                        onTap: () => _callNumber(patientPhone),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Text _appBarTitle() {
    return Text(widget.asSecretary ? 'لوحة الطبيب' : 'لوحة الطبيب');
  }

  Widget _filterChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip('الكل', DocApptFilter.all),
        _chip('قيد الانتظار', DocApptFilter.pending),
        _chip('مؤكّد', DocApptFilter.confirmed),
        _chip('ملغى', DocApptFilter.canceled),
      ],
    );
  }

  Widget _chip(String label, DocApptFilter value) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}
