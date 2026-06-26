import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

String appVersion = "";

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = true;
  bool saving = false;

  String? uid;

  @override
  void initState() {
    super.initState();
    _load();
    loadVersion(); // ✅ مهم
  }

  Future<void> loadVersion() async {
    final info = await PackageInfo.fromPlatform();

    setState(() {
      appVersion = "v${info.version} (${info.buildNumber})";
    });
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    uid = user.uid;
    emailController.text = user.email ?? '';

    final doc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(uid)
        .get();

    phoneController.text = doc.data()?['phone'] ?? '';

    setState(() => loading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= SAVE =================
  Future<void> saveChanges() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final newEmail = emailController.text.trim();
      final newPhone = phoneController.text.trim();

      // تحديث البريد
      if (newEmail != user.email) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(cred);
        await user.updateEmail(newEmail);
      }

      // تحديث الباسوورد
      if (newPasswordController.text.isNotEmpty) {
        if (newPasswordController.text != confirmPasswordController.text) {
          throw Exception(t.passwordsDoNotMatch);
        }

        await user.updatePassword(newPasswordController.text);
      }

      // تحديث Firestore
      await FirebaseFirestore.instance.collection('patients').doc(uid).set({
        'phone': newPhone,
      }, SetOptions(merge: true));

      snack(t.savedSuccessfully);
    } catch (e) {
      snack(e.toString());
    }

    setState(() => saving = false);
  }

  // ================= DELETE ACCOUNT =================
  Future<void> deleteAccount() async {
    final t = AppLocalizations.of(context)!;

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.confirmDelete),
        content: Text(t.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('patients').doc(uid).delete();

      await user.delete();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      snack(e.toString());
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(title: Text(t.patientSettings)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ================= ACCOUNT =================
            _card(
              child: Column(
                children: [
                  _field(emailController, t.email),
                  _field(phoneController, t.phoneNumber),

                  _field(
                    currentPasswordController,
                    t.currentPassword,
                    obscure: true,
                  ),
                  _field(newPasswordController, t.newPassword, obscure: true),
                  _field(
                    confirmPasswordController,
                    t.confirmNewPassword,
                    obscure: true,
                  ),

                  ElevatedButton(
                    onPressed: saving ? null : saveChanges,
                    child: Text(t.saveChanges),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= LANGUAGE =================
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.language),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: Localizations.localeOf(context).languageCode,
                    onChanged: (value) {
                      Provider.of<LanguageProvider>(
                        context,
                        listen: false,
                      ).changeLanguage(value!);
                    },
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= ABOUT =================
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.aboutApp),
                  const SizedBox(height: 8),

                  Text(
                    "Medical Booking $appVersion\n${t.appDescription}",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= DELETE =================
            _card(
              child: Column(
                children: [
                  Text(
                    t.deleteAccount,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: deleteAccount,
                    child: Text(t.delete),
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

  Widget _field(TextEditingController c, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
