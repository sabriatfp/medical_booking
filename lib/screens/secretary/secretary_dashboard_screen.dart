import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  int _current = 1; // نبدأ على "مواعيد اليوم"
  late final List<_Tab> _tabs;

  @override
  void initState() {
    super.initState();

    // ملاحظة مهمة:
    // سنمرّر hideInnerHeader:true للشاشات التي تحتوي على Header داخلي بعنوان + سهم
    // (DoctorScheduleScreen, DaysOffScreen, وقد تكون DoctorDashboardScreen / DoctorCalendarScreen
    //  إن كان فيهما ترويسة داخلية).
    _tabs = [
      _Tab(
        label: 'لوحة الطبيب',
        icon: Icons.dashboard_customize_rounded,
        builder: () => DoctorDashboardScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          // لو يوجد هيدر داخلي في هذه الشاشة سنُخفيه بهذا الباراميتر
          hideInnerHeader: true,
        ),
      ),
      _Tab(
        label: 'مواعيد اليوم',
        icon: Icons.today_outlined,
        // AppointmentsTodayScreen غالبًا بدون هيدر داخلي، نتركها كما هي
        builder: () => AppointmentsTodayScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true,
        ),
      ),
      _Tab(
        label: 'الرزنامة',
        icon: Icons.calendar_month_rounded,
        builder: () => DoctorCalendarScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true, // إن كان فيها ترويسة داخلية سيتم إخفاؤها
        ),
      ),
      _Tab(
        label: 'البرنامج',
        icon: Icons.schedule_rounded,
        builder: () => DoctorScheduleScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true, // مهم لإخفاء العنوان والسهم
        ),
      ),

      _Tab(
        label: 'أيام العطل',
        icon: Icons.beach_access_rounded,
        builder: () => DaysOffScreen(
          doctorId: widget.doctorId,
          asSecretary: true,
          hideInnerHeader: true, // مهم لإخفاء العنوان والسهم
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),

          // AppBar الرئيسي لفضاء السكريتير
          appBar: AppBar(
            elevation: 0,
            backgroundColor: kBrandColor,
            centerTitle: true,
            title: const Text(
              'فضاء السكريتير',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            automaticallyImplyLeading: false, // لا نعرض سهم رجوع هنا
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  final auth = FirebaseAuth.instance;

                  // في الحالتين سنعمل signOut
                  await auth.signOut();

                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login', // غيّر المسار إذا كان مختلفًا عندك
                      (_) => false,
                    );
                  }
                },
                tooltip: 'تسجيل الخروج',
              ),
            ],
          ),

          // محتوى التبويبات
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
                  (t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: t.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final Widget Function() builder;
  _Tab({required this.label, required this.icon, required this.builder});
}

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
