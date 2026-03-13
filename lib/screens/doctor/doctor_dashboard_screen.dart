import 'dart:async';

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

  /// إخفاء الهيدر الداخلي عندما تكون الشاشة مضمّنة في فضاء السكريتير
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

  // تشخيص انتظار الـ Stream
  Timer? _waitTimer;
  bool _streamWaitingTooLong = false;

  @override
  void initState() {
    super.initState();
    _resolveDoctorId();
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
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
      } else {
        debugPrint(
          '👨‍⚕️ DOCTOR DASH → doctorId=$_resolvedDoctorId, asSecretary=${widget.asSecretary}',
        );
      }
    } catch (e, st) {
      debugPrint('❌ ERROR resolving doctorId → $e\n$st');
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
    if (cleaned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متوفر')));
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')));
    }
  }

  /// اختبار مباشر للاستعلام خارج الـ Stream لمعرفة:
  /// - هل القواعد تمنع القراءة (permission-denied)؟
  /// - هل لا توجد بيانات؟
  Future<void> _testQuery(String doctorId, String? status) async {
    try {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId);

      if (status != null) {
        q = q.where('status', isEqualTo: status);
      }

      // ملاحظة: إذا كان اسم الحقل في بياناتك مختلف (مثل scheduledAt)، عدّل السطر أدناه:
      q = q.orderBy('dateTime'); // <-- عدّل إلى 'scheduledAt' إذا لزم

      final snap = await q.get();
      debugPrint(
        '🔎 TEST GET → ${snap.docs.length} docs (doctorId=$doctorId, status=$status)',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('قراءة مباشرة: ${snap.docs.length} عنصر')),
      );
    } on FirebaseException catch (e) {
      debugPrint('❌ TEST GET FIREBASE ERROR → ${e.code} ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'صلاحيات غير كافية لقراءة المواعيد (permission-denied).'
                : 'خطأ Firebase: ${e.code}',
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ TEST GET ERROR → $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ غير متوقع أثناء الاختبار')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: widget.hideInnerHeader ? null : AppBar(title: _appBarTitle()),
        body: Center(child: Text(_error!)),
      );
    }

    final doctorId = _resolvedDoctorId!;
    final currentStatus = _statusFromFilter();

    return Scaffold(
      appBar: widget.hideInnerHeader ? null : AppBar(title: _appBarTitle()),
      body: Column(
        children: [
          _filterChips(),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _doctorService.appointmentsStream(
                doctorId,
                currentStatus,
              ),
              builder: (context, snapshot) {
                // إدارة مؤقت الانتظار الطويل
                if (snapshot.connectionState == ConnectionState.waiting) {
                  _startWaitTimer(doctorId, currentStatus);
                } else {
                  _cancelWaitTimer();
                }

                if (snapshot.hasError) {
                  debugPrint('❌ APPTS STREAM ERROR → ${snapshot.error}');
                  return _errorView(
                    message: 'خطأ في تحميل المواعيد',
                    onTryDirectRead: () => _testQuery(doctorId, currentStatus),
                  );
                }

                if (!snapshot.hasData) {
                  return _waitingView(
                    isTakingLong: _streamWaitingTooLong,
                    onTryDirectRead: () => _testQuery(doctorId, currentStatus),
                  );
                }

                final docs = snapshot.data!.docs;
                debugPrint(
                  '📦 APPTS SNAP(${currentStatus ?? "all"}) → ${docs.length} docs',
                );

                if (docs.isEmpty) {
                  return _emptyView(
                    message: 'لا توجد مواعيد',
                    onTryDirectRead: () => _testQuery(doctorId, currentStatus),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();

                    // التاريخ/الوقت
                    DateTime? dt;
                    final dtAny =
                        d['dateTime']; // <-- عدّل لاسم الحقل إذا لزم (scheduledAt)
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
                                '❌ APPT UPDATE ERROR: ${e.code} ${e.message}',
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
                              debugPrint('❌ APPT UPDATE ERROR: $e');
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

  // ---------- واجهات مساعدة (انتظار/خطأ/لا بيانات) ----------

  Widget _waitingView({
    required bool isTakingLong,
    required VoidCallback onTryDirectRead,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            isTakingLong
                ? 'تأخر التحميل. تحقق من الاتصال أو الصلاحيات.'
                : 'جارٍ تحميل المواعيد...',
          ),
          if (isTakingLong) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onTryDirectRead,
              child: const Text('تجربة قراءة مباشرة'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorView({
    required String message,
    required VoidCallback onTryDirectRead,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onTryDirectRead,
            child: const Text('تجربة قراءة مباشرة'),
          ),
        ],
      ),
    );
  }

  Widget _emptyView({
    required String message,
    required VoidCallback onTryDirectRead,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onTryDirectRead,
            child: const Text('تحديث / تجربة قراءة مباشرة'),
          ),
        ],
      ),
    );
  }

  // ---------- AppBar + فلاتر ----------

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

  // ---------- إدارة مؤقت الانتظار الطويل ----------

  void _startWaitTimer(String doctorId, String? status) {
    if (_waitTimer != null) return; // مؤقت قائم بالفعل
    _streamWaitingTooLong = false;
    _waitTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() => _streamWaitingTooLong = true);
      debugPrint('⏳ STREAM WAIT TOO LONG (doctorId=$doctorId, status=$status)');
    });
  }

  void _cancelWaitTimer() {
    if (_waitTimer != null) {
      _waitTimer!.cancel();
      _waitTimer = null;
    }
    if (_streamWaitingTooLong) {
      setState(() => _streamWaitingTooLong = false);
    }
  }
}
