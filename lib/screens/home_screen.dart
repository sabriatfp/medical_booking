import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

import '../providers/language_provider.dart';
import '../services/doctor_service.dart';

// Patient screens
import 'package:medical_booking/screens/patient_settings_screen.dart';
import 'doctors_list_screen.dart';
import 'my_appointments_screen.dart';
import 'package:medical_booking/screens/doctors_filter_screen.dart';
// Doctor screens
import 'doctor/doctor_dashboard_screen.dart';
import 'doctor/doctor_schedule_screen.dart';
import 'doctor/days_off_screen.dart';
import 'doctor/doctor_calendar_screen.dart';
import 'doctor/doctor_finance_screen.dart';
import 'doctor/doctor_settings_screen.dart';
import 'doctor/doctor_onboarding_error_screen.dart';
// Auth
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const Color kBrandColor = Color(0xFF0ABAB5);

class _HomeScreenState extends State<HomeScreen> {
  final _doctorService = DoctorService();

  User? user;
  bool loading = true;
  bool isDoctor = false;

  String? doctorId;
  String? doctorName;
  String? patientName;

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

    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = userSnap.data() ?? {};
    isDoctor = (data['role'] ?? '') == 'doctor';

    if (isDoctor) {
      doctorId = await _doctorService.getDoctorId();

      if (doctorId == null || doctorId!.isEmpty) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const DoctorOnboardingErrorScreen(),
          ),
          (_) => false,
        );
        return; // ⛔ نوقف تحميل HomeScreen
      }
      // ✅ ✅ ✅ نهاية الـ guard

      final doctorSnap = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId!)
          .get();
      doctorName = doctorSnap.data()?['name'];
    } else {
      patientName = data['name'];
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final Color brand = kBrandColor;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final greeting = isDoctor
        ? "${t.welcomeDoctor} ${doctorName ?? t.defaultDoctor}"
        : "${t.welcomeUser} ${patientName ?? t.defaultUser}";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: brand,
          title: Text(t.home),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.language),
              onSelected: (value) {
                Provider.of<LanguageProvider>(
                  context,
                  listen: false,
                ).changeLanguage(value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'ar', child: Text(t.arabic)),
                PopupMenuItem(value: 'fr', child: Text(t.french)),
              ],
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: Column(
          children: [
            _HeaderGreeting(brandColor: brand, greeting: greeting),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isDoctor) ...[
                      _SectionTitle(title: t.patientServices, color: brand),
                      _ActionsGrid(
                        children: [
                          _ActionButton(
                            color: brand,
                            icon: Icons.search,
                            label: t.searchDoctors,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DoctorsFilterScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.local_hospital,
                            label: t.doctorsList,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DoctorsListScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.event_note,
                            label: t.myAppointments,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyAppointmentsScreen(),
                                ),
                              );
                            },
                          ),
                          _ActionButton(
                            color: brand,
                            icon: Icons.settings,
                            label: t.patientSettings,
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

                    if (isDoctor && doctorId != null) ...[
                      _SectionTitle(title: t.doctorDashboard, color: brand),

                      _ActionsGrid(
                        children: [
                          // 📊 Dashboard
                          _ActionButton(
                            color: brand,
                            icon: Icons.dashboard,
                            label: t.dashboard,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorDashboardScreen(
                                    doctorId: doctorId!,
                                  ),
                                ),
                              );
                            },
                          ),

                          // ⏰ Schedule
                          _ActionButton(
                            color: brand,
                            icon: Icons.schedule,
                            label: t.scheduleSettings,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DoctorScheduleScreen(doctorId: doctorId!),
                                ),
                              );
                            },
                          ),

                          // 📅 Calendar ✅ (كانت ناقصة)
                          _ActionButton(
                            color: brand,
                            icon: Icons.calendar_month,
                            label: t.calendar,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DoctorCalendarScreen(doctorId: doctorId!),
                                ),
                              );
                            },
                          ),

                          // 🏖 Days Off ✅ (كانت ناقصة)
                          _ActionButton(
                            color: brand,
                            icon: Icons.beach_access,
                            label: t.daysOff,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DaysOffScreen(doctorId: doctorId!),
                                ),
                              );
                            },
                          ),

                          // 💰 Finance ✅ (كانت ناقصة)
                          _ActionButton(
                            color: brand,
                            icon: Icons.attach_money,
                            label: t.finance,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DoctorFinanceScreen(),
                                ),
                              );
                            },
                          ),

                          // ⚙️ Settings
                          _ActionButton(
                            color: brand,
                            icon: Icons.settings,
                            label: t.doctorSettings,
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

/* ================= PRIVATE WIDGETS ================= */

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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              greeting,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
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
          Container(width: 4, height: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
