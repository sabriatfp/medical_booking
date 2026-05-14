import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// شاشات السكريتير/الطبيب
import 'package:medical_booking/features/secretary/ui/appointments_today_screen.dart';
import 'package:medical_booking/screens/doctor/doctor_dashboard_screen.dart';
import 'package:medical_booking/screens/doctor/doctor_schedule_screen.dart';
import 'package:medical_booking/screens/doctor/days_off_screen.dart';
import 'package:medical_booking/screens/doctor/doctor_calendar_screen.dart';

const Color kBrandColor = Color(0xFF0ABAB5);

class SecretaryDashboardScreen extends StatefulWidget {
  final String doctorId;
  const SecretaryDashboardScreen({super.key, required this.doctorId});

  @override
  State<SecretaryDashboardScreen> createState() =>
      _SecretaryDashboardScreenState();
}

class _SecretaryDashboardScreenState extends State<SecretaryDashboardScreen> {
  int _current = 1; // يبدأ على "مواعيد اليوم"
  late final List<_Tab> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      _Tab(
        labelKey: "doctorDashboard",
        icon: Icons.dashboard_customize_rounded,
        builder: () => DoctorDashboardScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true,
        ),
      ),
      _Tab(
        labelKey: "appointmentsToday",
        icon: Icons.today_outlined,
        builder: () => AppointmentsTodayScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true,
        ),
      ),
      _Tab(
        labelKey: "calendar",
        icon: Icons.calendar_month_rounded,
        builder: () => DoctorCalendarScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true,
        ),
      ),
      _Tab(
        labelKey: "scheduleSettings",
        icon: Icons.schedule_rounded,
        builder: () => DoctorScheduleScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true,
        ),
      ),
      _Tab(
        labelKey: "daysOff",
        icon: Icons.beach_access_rounded,
        builder: () => DaysOffScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true,
        ),
      ),
    ];
  }

  Future<bool> _onWillPop() async {
    if (_current != 1) {
      setState(() => _current = 1);
      return false;
    }
    return true;
  }

  Future<void> _logoutSecretary(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) return;

    final db = FirebaseFirestore.instance;

    // 1️⃣ سحب صلاحيات السكريتير (الأهم)
    await db.collection('users').doc(user.uid).update({
      'activeSecretaryDoctorId': FieldValue.delete(),
    });

    // 2️⃣ إغلاق session النشطة (اختياري لكنه ممتاز)
    final sessions = await db
        .collection('secretary_sessions')
        .where('secretaryUid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (sessions.docs.isNotEmpty) {
      await sessions.docs.first.reference.update({
        'status': 'closed',
        'endedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3️⃣ Logout من Firebase Auth
    await auth.signOut();

    // 4️⃣ الرجوع لشاشة Login
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),

          appBar: AppBar(
            elevation: 0,
            backgroundColor: kBrandColor,
            centerTitle: true,
            title: Text(
              t.secretarySpace,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: t.logout,
                onPressed: () async {
                  await _logoutSecretary(context);
                },
              ),
            ],
          ),

          body: IndexedStack(
            index: _current,
            children: _tabs.map((t) => _KeepAlive(child: t.builder())).toList(),
          ),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _current,
            onTap: (i) => setState(() => _current = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: kBrandColor,
            unselectedItemColor: const Color(0xFF6B7280),
            showUnselectedLabels: true,
            items: _tabs
                .map(
                  (tTab) => BottomNavigationBarItem(
                    icon: Icon(tTab.icon),
                    label: t.getString(tTab.labelKey),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// كلاس خاص بالمعلومات لكل Tab
class _Tab {
  final String labelKey; // مفتاح الترجمة
  final IconData icon;
  final Widget Function() builder;

  _Tab({required this.labelKey, required this.icon, required this.builder});
}

/// جعل كل Tab يحتفظ بحالته
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// ✅ إضافة getString كمساعد لجلب النصوص من AppLocalizations
extension LocalizationHelper on AppLocalizations {
  String getString(String key) {
    switch (key) {
      case "doctorDashboard":
        return doctorDashboard;
      case "appointmentsToday":
        return appointmentsToday;
      case "calendar":
        return calendar;
      case "scheduleSettings":
        return scheduleSettings;
      case "daysOff":
        return daysOff;
      default:
        return key;
    }
  }
}
