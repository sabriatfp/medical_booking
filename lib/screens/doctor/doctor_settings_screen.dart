import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:medical_booking/screens/doctor/generate_codes_screen.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final priceController = TextEditingController();
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isPriceVisible = true;

  String? doctorId;
  bool loading = true;
  bool updatingPassword = false;
  bool _initialized = false;
  bool updatingEmail = false;
  // ✅ Dropdown data
  List<QueryDocumentSnapshot> governorates = [];
  List<QueryDocumentSnapshot> specialties = [];

  String? selectedGovernorateId;
  String? selectedSpecialtyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      loadData();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    priceController.dispose();
    emailController.dispose();

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ================= LOAD DATA =================
  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    emailController.text = user.email ?? '';

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    doctorId = userDoc.data()?['doctorId'];
    if (doctorId == null) {
      setState(() => loading = false);
      return;
    }

    // تحميل القوائم
    await Future.wait([loadGovernorates(), loadSpecialties()]);

    final doctorDoc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    final data = doctorDoc.data();
    if (data != null) {
      nameController.text = data['name'] ?? '';
      phoneController.text = data['phone'] ?? '';
      addressController.text = data['address'] ?? '';
      priceController.text = (data['price'] ?? 0).toString();
      isPriceVisible = data['isPriceVisible'] ?? true;

      selectedGovernorateId = data['governorateId'];
      selectedSpecialtyId = data['specialtyId'];
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> loadGovernorates() async {
    final snap = await FirebaseFirestore.instance
        .collection('governorates')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get();
    governorates = snap.docs;
  }

  Future<void> loadSpecialties() async {
    final snap = await FirebaseFirestore.instance
        .collection('specialties')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get();
    specialties = snap.docs;
  }

  // ================= IMAGE =================

  // ================= SAVE =================
  Future<void> saveChanges() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final lang = Localizations.localeOf(context).languageCode;

    final govDoc = governorates.firstWhere(
      (e) => e.id == selectedGovernorateId,
    );
    final specDoc = specialties.firstWhere((e) => e.id == selectedSpecialtyId);

    await FirebaseFirestore.instance.collection('doctors').doc(doctorId).update(
      {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0,
        'isPriceVisible': isPriceVisible,

        // ✅ بيانات البحث
        'governorateId': selectedGovernorateId,
        'governorateLabel':
            (govDoc.data() as Map<String, dynamic>)['name_$lang'] ??
            (govDoc.data() as Map<String, dynamic>)['name_fr'],

        'specialtyId': selectedSpecialtyId,
        'specialtyLabel':
            (specDoc.data() as Map<String, dynamic>)['name_$lang'] ??
            (specDoc.data() as Map<String, dynamic>)['name_fr'],
      },
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.savedSuccessfully)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(title: Text(t.doctorSettings)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  _field(nameController, t.fullName),

                  DropdownButtonFormField<String>(
                    value: selectedSpecialtyId,
                    decoration: _inputDecoration(t.specialty),
                    items: specialties.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(d['name_$lang'] ?? d['name_fr']),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedSpecialtyId = v),
                    validator: (v) => v == null ? t.chooseSpecialty : null,
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedGovernorateId,
                    decoration: _inputDecoration(t.governorate),
                    items: governorates.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(d['name_$lang'] ?? d['name_fr']),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedGovernorateId = v),
                    validator: (v) => v == null ? t.chooseGovernorate : null,
                  ),

                  const SizedBox(height: 16),
                  _field(phoneController, t.phoneNumber),
                  _field(addressController, t.address),

                  ElevatedButton(
                    onPressed: saveChanges,
                    child: Text(t.saveChanges),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              child: Column(
                children: [
                  _field(
                    priceController,
                    t.sessionPrice,
                    keyboard: TextInputType.number,
                  ),
                  SwitchListTile(
                    title: Text(t.showPrice),
                    value: isPriceVisible,
                    onChanged: (v) => setState(() => isPriceVisible = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              child: Column(
                children: [
                  Text(t.secretaryManagement),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code),
                    label: Text(t.manageSecretary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GenerateCodesScreen(doctorId: doctorId!),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              child: Column(
                children: [
                  _field(emailController, t.email),
                  ElevatedButton(
                    onPressed: updatingEmail ? null : updateEmail,
                    child: updatingEmail
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.updateEmail),
                  ),
                  const SizedBox(height: 10),
                  // ✅ كلمة المرور الحالية
                  _field(
                    currentPasswordController,
                    t.currentPassword,
                    obscure: true,
                  ),

                  // ✅ كلمة المرور الجديدة
                  _field(newPasswordController, t.newPassword, obscure: true),

                  // ✅ تأكيد كلمة المرور الجديدة
                  _field(
                    confirmPasswordController,
                    t.confirmNewPassword,
                    obscure: true,
                  ),

                  ElevatedButton(
                    onPressed: updatingPassword ? null : updatePassword,
                    child: updatingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.updatePassword),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> updateEmail() async {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (updatingEmail) return;

    setState(() => updatingEmail = true);

    try {
      if (user == null || user.email == null) {
        throw Exception(t.unexpectedError);
      }

      if (currentPasswordController.text.isEmpty) {
        throw Exception(t.currentPasswordRequired);
      }

      // ✅ إعادة التحقق بكلمة المرور الحالية
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // ✅ تحديث الإيميل
      await user.updateEmail(emailController.text.trim());

      // ✅ مستحسن جدًا
      await user.sendEmailVerification();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.emailUpdated)));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'wrong-password'
                ? t.currentPasswordIncorrect
                : (e.message ?? t.unexpectedError),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => updatingEmail = false);
      }
    }
  }

  Future<void> updatePassword() async {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (updatingPassword) return; // ✅ منع الضغط المتكرر

    setState(() => updatingPassword = true);

    try {
      if (user == null || user.email == null) {
        throw Exception(t.unexpectedError);
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        throw Exception(t.passwordsDoNotMatch);
      }

      if (newPasswordController.text.length < 6) {
        throw Exception(t.passwordTooShort);
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPasswordController.text.trim());

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.passwordUpdated)));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'wrong-password'
                ? t.currentPasswordIncorrect
                : (e.message ?? t.unexpectedError),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => updatingPassword = false);
      }
    }
  }
}
