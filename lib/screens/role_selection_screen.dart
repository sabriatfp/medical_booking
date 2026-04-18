import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'doctor/doctor_terms_screen.dart';
import 'signup_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.appBarCreateAccount)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 64, color: scheme.primary),
                const SizedBox(height: 12),

                // ✅ "اختر نوع الحساب"
                Text(
                  t.chooseAccountType,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // ✅ "هل تريد استخدام التطبيق كمريض أم كطبيب؟"
                Text(t.patientOrDoctor, textAlign: TextAlign.center),

                const SizedBox(height: 32),

                // ✅ زر التسجيل كمريض
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person),
                    label: Text(t.registerPatient),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignUpScreen(role: 'patient'),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ زر التسجيل كطبيب
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.medical_services),
                    label: Text(t.registerDoctor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorTermsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
