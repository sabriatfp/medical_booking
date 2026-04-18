// lib/services/appointment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة إدارة المواعيد (للطبيب أو السكريتير أو النظام)
class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentUid;

  AppointmentService(this.currentUid);

  /// ✅ تأكيد الموعد (Doctor or Secretary)
  Future<void> confirm(String apptId) async {
    await _db.collection('appointments').doc(apptId).update({
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
      'confirmedBy': currentUid,
    });
  }

  /// ✅ تسجيل الحضور (Check‑in)
  Future<void> checkIn(String apptId) async {
    await _db.collection('appointments').doc(apptId).update({
      'status': 'checked_in',
      'checkedInAt': FieldValue.serverTimestamp(),
      'checkedInBy': currentUid,
    });
  }

  /// ✅ تحويل كل مواعيد اليوم (confirmed → no_show) إذا لم يحضر أصحابها
  /// يُستخدم عادة:
  /// - عند نهاية اليوم تلقائياً
  /// - عند ضغط زر «تحديث الغياب»
  Future<int> markDayNoShows({
    required String doctorId,
    required DateTime dayLocal,
  }) async {
    // اليوم المحلي من 00:00 إلى 23:59
    final localStart = DateTime(
      dayLocal.year,
      dayLocal.month,
      dayLocal.day,
      0,
      0,
      0,
    );
    final localEnd = localStart.add(const Duration(days: 1));

    // تحويل للنطاق UTC (Firestore)
    final startUtc = localStart.toUtc();
    final endUtc = localEnd.toUtc();

    // نبحث فقط في المواعيد المؤكدة (confirmed)
    final q = await _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'confirmed')
        .where('slot.start', isGreaterThanOrEqualTo: startUtc.toIso8601String())
        .where('slot.start', isLessThan: endUtc.toIso8601String())
        .limit(400)
        .get();

    if (q.docs.isEmpty) return 0;

    final batch = _db.batch();

    for (final d in q.docs) {
      batch.update(d.reference, {
        'status': 'no_show',
        'noShowAt': FieldValue.serverTimestamp(),
        'noShowBy': currentUid,
      });
    }

    await batch.commit();
    return q.docs.length;
  }
}
