import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorService {
  final _fire = FirebaseFirestore.instance;

  Future<String?> getDoctorId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap = await _fire.collection('users').doc(user.uid).get();
    return snap.data()?['doctorId'];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> appointmentsStream(
    String doctorId,
    String? status,
  ) {
    Query<Map<String, dynamic>> q = _fire
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId);

    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }

    return q.orderBy('dateTime').snapshots();
  }

  Future<void> updateAppointmentStatus(String apptId, String status) {
    return _fire.collection('appointments').doc(apptId).update({
      'status': status,
    });
  }
}
