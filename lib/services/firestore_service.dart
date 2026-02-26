import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUser({
    required String uid,
    required String email,
    required String role,
    String? name,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'role': role,
      'name': name ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
