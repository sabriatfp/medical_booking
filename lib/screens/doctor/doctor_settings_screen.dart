import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medical_booking/screens/doctor/generate_codes_screen.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final specialtyController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final priceController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPriceVisible = true;

  String? doctorId;
  String? photoUrl;
  File? selectedImage;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

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

    final doctorDoc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    final data = doctorDoc.data();

    if (data != null) {
      nameController.text = data['name'] ?? '';
      specialtyController.text = data['specialty'] ?? '';
      phoneController.text = data['phone'] ?? '';
      addressController.text = data['address'] ?? '';
      priceController.text = (data['price'] ?? 0).toString();
      isPriceVisible = data['isPriceVisible'] ?? true;
      photoUrl = data['photoUrl'];
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final path = picked.path;
      if (path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر قراءة مسار الصورة')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        selectedImage = File(path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل اختيار الصورة: $e')));
    }
  }

  Future<String?> uploadImage() async {
    // لو ما اخترنا صورة جديدة، نعيد الرابط القديم كما هو
    if (selectedImage == null) return photoUrl;

    if (doctorId == null || doctorId!.isEmpty) {
      throw Exception('معرّف الطبيب غير جاهز بعد. أعد المحاولة لاحقًا.');
    }

    final file = selectedImage!;
    if (!await file.exists()) {
      throw Exception('الملف غير موجود على الجهاز.');
    }

    // ⚠️ تأكد من تفعيل Firebase Storage وإعداد القواعد
    final ref = FirebaseStorage.instance.ref('doctor_photos/${doctorId!}.jpg');

    try {
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw Exception('فشل الرفع: ${e.message ?? e.code}');
    }
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (doctorId == null || doctorId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("البيانات لم تكتمل بعد. أعد المحاولة.")),
      );
      return;
    }

    try {
      final newPhotoUrl = await uploadImage();
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .update({
            'name': nameController.text.trim(),
            'specialty': specialtyController.text.trim(),
            'phone': phoneController.text.trim(),
            'address': addressController.text.trim(),
            'price': double.tryParse(priceController.text) ?? 0,
            'isPriceVisible': isPriceVisible,
            'photoUrl': newPhotoUrl,
          });

      if (!mounted) return;
      setState(() {
        photoUrl = newPhotoUrl; // تحدّث المعاينة
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم حفظ التعديلات")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> updateEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.updateEmail(emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم تحديث البريد")));
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'requires-recent-login'
          ? 'الأمان: رجاءً سجّل الدخول من جديد ثم حاول تحديث البريد.'
          : (e.message ?? 'تعذّر تحديث البريد');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.updatePassword(passwordController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم تحديث كلمة المرور")));
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'requires-recent-login'
          ? 'الأمان: رجاءً سجّل الدخول من جديد ثم حاول تحديث كلمة المرور.'
          : (e.message ?? 'تعذّر تحديث كلمة المرور');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("إعدادات الحساب"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// 🔵 معلومات شخصية
              _buildSectionCard(
                icon: Icons.person,
                title: "المعلومات الشخصية",
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!) as ImageProvider
                            : (photoUrl != null && photoUrl!.isNotEmpty
                                  ? NetworkImage(photoUrl!)
                                  : null),
                        child:
                            (selectedImage == null &&
                                (photoUrl == null || photoUrl!.isEmpty))
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(nameController, "الاسم"),
                    _buildTextField(specialtyController, "الاختصاص"),
                    _buildTextField(phoneController, "رقم الهاتف"),
                    _buildTextField(addressController, "العنوان"),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading || doctorId == null
                            ? null
                            : saveChanges,
                        child: const Text("حفظ التعديلات"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🟢 السعر
              _buildSectionCard(
                icon: Icons.attach_money,
                title: "إعدادات السعر",
                child: Column(
                  children: [
                    _buildTextField(
                      priceController,
                      "السعر",
                      keyboard: TextInputType.number,
                    ),
                    SwitchListTile(
                      title: const Text("إظهار السعر للمرضى"),
                      value: isPriceVisible,
                      onChanged: (val) => setState(() => isPriceVisible = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🟣 أكواد السكريتير
              _buildSectionCard(
                icon: Icons.badge_outlined,
                title: "أكواد السكريتير",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "أنشئ أكواد دخول للسكريتير، فعّل/عطّل الأكواد، وحدد صلاحية انتهاء.",
                      style: TextStyle(height: 1.2),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_2_outlined),
                        label: const Text("إدارة أكواد السكريتير"),
                        onPressed: (doctorId == null || doctorId!.isEmpty)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GenerateCodesScreen(
                                      doctorId: doctorId!,
                                    ),
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),

              /// 🔐 الأمان
              _buildSectionCard(
                icon: Icons.security,
                title: "أمان الحساب",
                child: Column(
                  children: [
                    _buildTextField(emailController, "البريد الإلكتروني"),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateEmail,
                        child: const Text("تحديث البريد"),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      passwordController,
                      "كلمة المرور الجديدة",
                      obscure: true,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updatePassword,
                        child: const Text("تحديث كلمة المرور"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        // Validators بسيطة (اختياري)
        validator: (v) {
          if (label == 'الاسم' && (v == null || v.trim().length < 2)) {
            return 'أدخل اسمًا صحيحًا';
          }
          if (label == 'السعر' && controller == priceController) {
            final n = double.tryParse(v?.trim() ?? '');
            if (n == null || n < 0) return 'أدخل رقمًا صحيحًا';
          }
          return null;
        },
      ),
    );
  }
}
