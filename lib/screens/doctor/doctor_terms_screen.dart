import 'package:flutter/material.dart';
import 'doctor_register_screen.dart';

class DoctorTermsScreen extends StatefulWidget {
  const DoctorTermsScreen({super.key});

  @override
  State<DoctorTermsScreen> createState() => _DoctorTermsScreenState();
}

class _DoctorTermsScreenState extends State<DoctorTermsScreen> {
  bool accepted = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('شروط حساب الطبيب')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      '''
إقرار وتعهد خاص بحسابات الأطباء

باستخدامك للتطبيق بصفتك طبيبًا، فإنك تقر وتتعهد بما يلي:

1) أنك طبيب مرخّص لك بمزاولة المهنة، وجميع المعلومات التي تدخلها صحيحة ومحدّثة.
2) تتحمّل كامل المسؤولية القانونية والمهنية عن بياناتك.
3) التطبيق لا يتحمّل مسؤولية صحة المعلومات التي يضيفها الأطباء.
4) التطبيق مخصّص لتنظيم المواعيد فقط.
5) انتحال صفة طبيب أو إدخال معلومات مضللة قد يعرّض الحساب للحذف والمساءلة.
6) يحق لإدارة التطبيق طلب وثائق تثبت الصفة المهنية.

بمتابعتك، فإنك توافق على جميع الشروط أعلاه.
                      ''',
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: accepted,
                  onChanged: (v) => setState(() => accepted = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'أقرّ بأنني طبيب مرخّص وأتحمّل المسؤولية الكاملة عن صحة معلوماتي.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                onPressed: accepted
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DoctorRegisterScreen(),
                          ),
                        );
                      }
                    : null,
                label: const Text('متابعة إنشاء الحساب'),
              ),
            ),
            const SizedBox(height: 6),
            if (!accepted)
              Text('يرجى الموافقة على الشروط أولًا', style: TextStyle(color: scheme.error)),
          ],
        ),
      ),
    );
  }
}