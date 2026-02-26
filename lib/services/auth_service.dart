
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<UserCredential> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('يرجى إدخال البريد الإلكتروني وكلمة المرور');
    }
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapCodeToMessage(e));
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
  if (email.isEmpty || password.isEmpty) {
    throw Exception('يرجى إدخال البريد الإلكتروني وكلمة المرور');
  }

  try {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // 🔥 حفظ المستخدم في Firestore
    await FirestoreService().createUser(
      uid: cred.user!.uid,
      email: cred.user!.email!,
      role: 'patient', // افتراضيًا
    );

    return cred;
  } on FirebaseAuthException catch (e) {
    throw Exception(_mapCodeToMessage(e));
  }
}
  Future<void> signOut() async => _auth.signOut();

  String _mapCodeToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'البريد الإلكتروني غير صالح';
      case 'user-not-found': return 'لا يوجد مستخدم بهذا البريد';
      case 'wrong-password': return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use': return 'البريد مستخدم مسبقًا';
      case 'weak-password': return 'كلمة المرور ضعيفة';
      case 'too-many-requests': return 'محاولات كثيرة، حاول لاحقًا';
      default: return 'فشل العملية: ${e.message}';
    }
  }
}