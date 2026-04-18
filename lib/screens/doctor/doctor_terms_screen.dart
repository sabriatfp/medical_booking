import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:medical_booking/screens/signup_screen.dart';

class DoctorTermsScreen extends StatefulWidget {
  const DoctorTermsScreen({super.key});

  @override
  State<DoctorTermsScreen> createState() => _DoctorTermsScreenState();
}

class _DoctorTermsScreenState extends State<DoctorTermsScreen> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.doctorTerms), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===============================
            // ✅ نص التعهد
            // ===============================
            Expanded(
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      t.doctorAgreementDetails,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===============================
            // ✅ Checkbox الموافقة
            // ===============================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: accepted,
                  onChanged: (v) => setState(() => accepted = v ?? false),
                ),
                Expanded(
                  child: Text(
                    t.doctorAgreementConfirm,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ===============================
            // ✅ زر المتابعة
            // ===============================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                onPressed: accepted
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(role: 'doctor'),
                          ),
                        );
                      }
                    : null,
                label: Text(t.acceptAndContinue),
              ),
            ),

            const SizedBox(height: 6),

            // ===============================
            // ✅ تنبيه في حالة عدم الموافقة
            // ===============================
            if (!accepted)
              Text(t.mustAcceptTerms, style: TextStyle(color: scheme.error)),
          ],
        ),
      ),
    );
  }
}
