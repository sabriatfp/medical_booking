import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/screens/home_screen.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final specialty = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();
  final price = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    specialty.dispose();
    address.dispose();
    phone.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> _registerDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // إنشاء مستخدم في Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final uid = cred.user!.uid;

      // إنشاء وثيقة الطبيب داخل doctors (docId تلقائي)
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .add({
            "ownerUid": uid,
            "name": name.text.trim(),
            "specialty": specialty.text.trim(),
            "address": address.text.trim(),
            "phone": phone.text.trim(),
            "price": int.tryParse(price.text) ?? 0,
            "rating": 0,
            "isAvailable": true,
            "photoUrl": "",
            "createdAt": FieldValue.serverTimestamp(),
          });

      // إنشاء ملف المستخدم داخل users
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": name.text.trim(),
        "email": email.text.trim(),
        "role": "doctor",
        "doctorId": doctorDoc.id, // أهم سطر
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      // بعد إنشاء حساب الطبيب، انتقل مباشرة إلى HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إنشاء حساب الطبيب بنجاح")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل طبيب")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: name,
                decoration: _dec("الاسم", Icons.badge),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: email,
                decoration: _dec("البريد", Icons.email),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: password,
                decoration: _dec("كلمة المرور", Icons.lock),
                obscureText: true,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: specialty,
                decoration: _dec("التخصص", Icons.medical_services),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: address,
                decoration: _dec("العنوان", Icons.place),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: phone,
                decoration: _dec("رقم الهاتف", Icons.phone),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: price,
                decoration: _dec("سعر الكشف", Icons.attach_money),
              ),
              const SizedBox(height: 20),

              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: loading ? null : _registerDoctor,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("إنشاء حساب طبيب"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
