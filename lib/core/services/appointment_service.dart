import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentUid;

  AppointmentService(this.currentUid);

  Future<void> confirm(String apptId) async {
    await _db.collection('appointments').doc(apptId).update({
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
      'confirmedBy': currentUid,
    });
  }

  Future<void> checkIn(String apptId) async {
    await _db.collection('appointments').doc(apptId).update({
      'status': 'checked_in',
      'checkedInAt': FieldValue.serverTimestamp(),
      'checkedInBy': currentUid,
    });
  }

  /// تحويل كل مواعيد "اليوم المحدد" التي بقيت confirmed ولم تُسجّل حضوراً إلى no_show.
  /// يعمل يدوياً عبر زرّ أو تلقائياً عند فتح الشاشة بعد نهاية الدوام.
  Future<int> markDayNoShows({
    required String doctorId,
    required DateTime dayLocal, // اليوم المحلي (بدون وقت)
  }) async {
    // نحسب نافذة اليوم محلياً ثم نحوّل إلى UTC
    final localStart = DateTime(
      dayLocal.year,
      dayLocal.month,
      dayLocal.day,
      0,
      0,
      0,
    );
    final localEnd = localStart.add(const Duration(days: 1));

    final startUtc = localStart.toUtc();
    final endUtc = localEnd.toUtc();

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
