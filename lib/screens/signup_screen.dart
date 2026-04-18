import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  final String role; // 'patient' | 'doctor'
  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();

  // Dropdown data
  List<QueryDocumentSnapshot> governorates = [];
  List<QueryDocumentSnapshot> specialties = [];

  String? selectedGovernorateId;
  String? selectedSpecialtyId;

  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'doctor') {
      loadDropdownData();
    }
  }

  Future<void> loadDropdownData() async {
    final govSnap = await FirebaseFirestore.instance
        .collection('governorates')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get();

    final specSnap = await FirebaseFirestore.instance
        .collection('specialties')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get();

    setState(() {
      governorates = govSnap.docs;
      specialties = specSnap.docs;
    });
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      // اختياري — بدون أي تحقق لاحق
      await cred.user!.sendEmailVerification();

      final uid = cred.user!.uid;
      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // users collection
      await usersRef.set({
        'name': name.text.trim(),
        'email': email.text.trim(),
        'role': widget.role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (widget.role == 'patient') {
        await FirebaseFirestore.instance.collection('patients').doc(uid).set({
          'phone': phone.text.trim(),
          'allowPush': true,
          'fcmTokens': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (widget.role == 'doctor') {
        final lang = Localizations.localeOf(context).languageCode;

        final govDoc = governorates.firstWhere(
          (e) => e.id == selectedGovernorateId,
        );
        final specDoc = specialties.firstWhere(
          (e) => e.id == selectedSpecialtyId,
        );

        final governorateLabel =
            (govDoc.data() as Map<String, dynamic>)['name_$lang'] ??
            (govDoc.data() as Map<String, dynamic>)['name_fr'];

        final specialtyLabel =
            (specDoc.data() as Map<String, dynamic>)['name_$lang'] ??
            (specDoc.data() as Map<String, dynamic>)['name_fr'];

        // ✅ 1️⃣ إنشاء doctorId صريح
        final doctorRef = FirebaseFirestore.instance
            .collection('doctors')
            .doc();

        await doctorRef.set({
          'ownerUid': uid,
          'name': name.text.trim(),
          'email': email.text.trim(),

          'specialtyId': selectedSpecialtyId,
          'specialtyLabel': specialtyLabel,

          'governorateId': selectedGovernorateId,
          'governorateLabel': governorateLabel,

          'phone': phone.text.trim(),
          'address': address.text.trim(),

          'price': null,
          'rating': 0,
          'photoUrl': '',
          'isAvailable': true,

          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ 2️⃣ ربط user بالـ doctorId (الحل الجذري)
        try {
          await usersRef.set({
            'doctorId': doctorRef.id,
          }, SetOptions(merge: true));

          debugPrint("✅ doctorId saved successfully");
        } catch (e) {
          debugPrint("❌ FAILED to save doctorId: $e");
          rethrow;
        }
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => t.invalidEmail,
        'email-already-in-use' => t.emailInUse,
        'weak-password' => t.weakPassword,
        _ => '${t.error}: ${e.message}',
      };
      setState(() => error = msg);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isPatient = widget.role == 'patient';
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(isPatient ? t.registerPatient : t.register)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // الاسم
                      TextFormField(
                        controller: name,
                        decoration: _dec(t.fullName, Icons.badge),
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? t.enterValidName
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // البريد
                      TextFormField(
                        controller: email,
                        decoration: _dec(t.email, Icons.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return t.enterEmail;
                          if (!v.contains('@')) return t.invalidEmail;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // كلمة المرور
                      TextFormField(
                        controller: password,
                        decoration: _dec(t.password6Chars, Icons.lock),
                        obscureText: true,
                        validator: (v) => (v == null || v.length < 6)
                            ? t.enterValidPassword
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // تأكيد كلمة المرور
                      TextFormField(
                        controller: confirmPassword,
                        decoration: _dec(t.confirmPassword, Icons.lock_outline),
                        obscureText: true,
                        validator: (v) =>
                            v != password.text ? t.passwordsNotMatch : null,
                      ),
                      const SizedBox(height: 12),

                      // الهاتف (إجباري للمريض)
                      TextFormField(
                        controller: phone,
                        decoration: _dec(t.phoneNumber, Icons.phone),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (widget.role == 'patient') {
                            if (v == null || v.trim().length < 6) {
                              return t.enterValidPhone;
                            }
                          }
                          return null;
                        },
                      ),

                      if (!isPatient) ...[
                        // الاختصاص
                        DropdownButtonFormField<String>(
                          value: selectedSpecialtyId,
                          decoration: _dec(t.specialty, Icons.medical_services),
                          items: specialties.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(d['name_$lang'] ?? d['name_fr']),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => selectedSpecialtyId = v),
                          validator: (v) =>
                              v == null ? t.chooseSpecialty : null,
                        ),

                        const SizedBox(height: 12),

                        // الولاية
                        DropdownButtonFormField<String>(
                          value: selectedGovernorateId,
                          decoration: _dec(t.governorate, Icons.location_on),
                          items: governorates.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(d['name_$lang'] ?? d['name_fr']),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => selectedGovernorateId = v),
                          validator: (v) =>
                              v == null ? t.chooseGovernorate : null,
                        ),

                        const SizedBox(height: 12),

                        // الهاتف
                        // TextFormField(
                        // controller: phone,
                        //  decoration: _dec(t.phoneNumber, Icons.phone),
                        //  keyboardType: TextInputType.phone,
                        //  validator: (v) => (v == null || v.trim().length < 6)
                        //     ? t.enterValidPhone
                        //    : null,
                        // ),
                        const SizedBox(height: 12),

                        // العنوان
                        TextFormField(
                          controller: address,
                          decoration: _dec(t.address, Icons.place),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? t.enterAddress
                              : null,
                        ),
                      ],

                      const SizedBox(height: 16),

                      if (error != null)
                        Text(error!, style: const TextStyle(color: Colors.red)),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : _signUp,
                          icon: const Icon(Icons.person_add),
                          label: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(t.createAccount),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
