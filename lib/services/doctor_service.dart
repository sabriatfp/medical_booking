// lib/services/doctor_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorService {
  // ✅ تعريف مرجع Firestore داخل الكلاس
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  DoctorService();

  /// يعيد ستريم المواعيد لطبيب معيّن مع فلترة حالة اختيارية
  Stream<QuerySnapshot<Map<String, dynamic>>> appointmentsStream(
    String doctorId,
    String? status,
  ) {
    Query<Map<String, dynamic>> q = _fs
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId);

    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }

    // ملاحظة: لو استعملت where + orderBy قد يطلب Firestore فهرس مركب
    return q.orderBy('dateTime', descending: false).snapshots();
  }

  /// تحديث حالة الموعد مع ميتاداتا (متوافقة مع القواعد)
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = FieldValue.serverTimestamp();

    final Map<String, dynamic> data = {'status': status};

    switch (status) {
      case 'confirmed':
        data['confirmedAt'] = now;
        data['confirmedBy'] = uid;
        break;

      case 'checked_in':
        data['checkedInAt'] = now;
        data['checkedInBy'] = uid;
        break;

      case 'no_show':
        data['noShowAt'] = now;
        data['noShowBy'] = uid;
        break;

      case 'canceled':
        data['canceledAt'] = now;
        data['canceledBy'] = uid;
        break;
    }

    // ✅ هنا لن تكون تحتها خط أحمر لأن _fs معرّفة
    await _fs.collection('appointments').doc(appointmentId).update(data);
  }

  /// استنتاج doctorId للمستخدم الحالي (عدّل حسب سكيمتك)
  /// إذا عندك users/{uid}.doctorId نقرأه من هناك، وإلا عدّل حسب لوجيكك.
  Future<String?> getDoctorId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    // مثال 1: من users/{uid}.doctorId
    final userDoc = await _fs.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data != null &&
        data['doctorId'] is String &&
        (data['doctorId'] as String).isNotEmpty) {
      return data['doctorId'] as String;
    }

    // مثال 2: من doctors حيث ownerUid == uid (لو هذا هو ربطك)
    final q = await _fs
        .collection('doctors')
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      return q.docs.first.id; // معرّف الوثيقة هو doctorId
    }

    return null;
  }
}
