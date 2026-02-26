import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/doctor_service.dart';

// ⬅️ عدّل هذا المسار حسب مكان الملف عندك
import 'patient_settings_screen.dart';
// شاشات المريض
import 'doctors_list_screen.dart';
import 'my_appointments_screen.dart';

// شاشات الطبيب
import 'doctor/doctor_dashboard_screen.dart';
import 'doctor/doctor_schedule_screen.dart';
import 'doctor/days_off_screen.dart';
import 'doctor/doctor_calendar_screen.dart';
import 'doctor/doctor_finance_screen.dart';
import 'doctor/doctor_settings_screen.dart';

// المصادقة
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ✅ حدّد لون الشعار هنا (نفس لون شاشة التسجيل)
const Color kBrandColor = Color(0xFF0ABAB5); // مثال Teal-Blue — يمكن تغييره

class _HomeScreenState extends State<HomeScreen> {
  final _doctorService = DoctorService();

  User? user;
  bool loading = true;
  bool isDoctor = false;
  String? doctorId;
  String? doctorName;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  Future<void> _initUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    final uid = user!.uid;

    // جلب doctorId من الخدمة
    doctorId = await _doctorService.getDoctorId();

    // تحديد الدور من users/{uid}
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = userSnap.data() ?? {};
    isDoctor = data['role'] == 'doctor';

    // جلب اسم الطبيب إذا وُجد
    if (isDoctor && doctorId != null) {
      final doctorSnap = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();
      doctorName = doctorSnap.data()?['name'];
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // بإمكانك استبدال kBrandColor بـ Theme.of(context).colorScheme.primary إذا ضبطت الـ Theme
    final Color brand = kBrandColor;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return const Scaffold(body: Center(child: Text('لم يتم تسجيل الدخول')));
    }

    final String greeting = isDoctor
        ? "مرحبًا د. ${doctorName ?? 'طبيب'} "
        : "مرحبًا يا ${user?.email ?? 'مستخدم'} ";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: brand,
          title: const Text('الصفحة الرئيسية'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: _logout,
            ),
          ],
        ),
        body: Column(
          children: [
            // ===== Header ترحيبي بنفس لون الشعار =====
            _HeaderGreeting(brandColor: brand, greeting: greeting),

            // ===== محتوى منسّق =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isDoctor) ...[
                      _SectionTitle(title: 'خدمات المريض', color: brand),

                      _ActionsGrid(
                        children: [
                          _ActionButton(
                            color: brand,
                            icon: Icons.local_hospital_rounded,
                            label: 'قائمة الأطباء',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DoctorsListScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.event_note_rounded,
                            label: 'مواعيدي',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyAppointmentsScreen(),
                                ),
                              );
                            },
                          ),
                          // ✅ زر إعدادات المريض
                          _ActionButton(
                            color: brand,
                            icon: Icons.settings_rounded,
                            label: 'إعدادات المريض',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PatientSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],

                    if (isDoctor) ...[
                      _SectionTitle(title: 'لوحة الطبيب', color: brand),

                      _ActionsGrid(
                        children: [
                          _ActionButton(
                            color: brand,
                            icon: Icons.dashboard_customize_rounded,
                            label: 'لوحة الطبيب',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DoctorDashboardScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.schedule_rounded,
                            label: 'إعدادات التوقيت',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DoctorScheduleScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.beach_access_rounded,
                            label: 'العطل الخاصة',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DaysOffScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.calendar_month_rounded,
                            label: 'الرزنامة',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DoctorCalendarScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.attach_money_rounded,
                            label: 'المالية',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DoctorFinanceScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.settings_suggest_rounded,
                            label: 'الإعدادات',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DoctorSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======= Widgets مساعدة =======

class _HeaderGreeting extends StatelessWidget {
  final Color brandColor;
  final String greeting;

  const _HeaderGreeting({required this.brandColor, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandColor, brandColor.withOpacity(0.85)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              greeting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  final List<Widget> children;

  const _ActionsGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.08,
      children: children,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.18), width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
