import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> secretaryDoctorId(String uid) async {
    final doc = await _db.collection('user_roles').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return data['secretaryOf'] as String?;
  }
}
