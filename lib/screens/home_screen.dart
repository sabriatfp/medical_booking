import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
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
import 'doctor/doctor_subscription_expired_screen.dart';
// Auth
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const Color kBrandColor = Color(0xFF0ABAB5);

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _doctorService = DoctorService();
  final AudioPlayer _player = AudioPlayer();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  int _lastPatientNotif = 0;
  int _lastDoctorNotif = 0;
  int _lastReportNotif = 0;
  int _lastSubNotif = 0; // للاشتراك
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
    _checkSubscriptionNotification();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initUserData() async {
    user = FirebaseAuth.instance.currentUser;

    // 🔐 المستخدم غير مسجل
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

    try {
      // 1️⃣ جلب user document (Source of Truth)
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = userSnap.data();
      if (data == null) {
        throw Exception('User document not found');
      }

      isDoctor = (data['role'] ?? '') == 'doctor';

      // =====================================
      // ✅ GUARD 1: فحص الاشتراك للطبيب فقط
      // =====================================
      if (isDoctor) {
        final bool subscriptionActive = data['subscriptionActive'] == true;

        final Timestamp? subEndTs = data['subscriptionEnd'] as Timestamp?;

        final bool isSubscriptionValid =
            subscriptionActive &&
            subEndTs != null &&
            subEndTs.toDate().isAfter(DateTime.now().toUtc());

        // ❌ الاشتراك منتهي أو غير مفعل
        if (!isSubscriptionValid) {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DoctorSubscriptionExpiredScreen(),
            ),
          );
          return; // ⛔ نمنع الدخول لبقية HomeScreen
        }
      }

      // =====================================
      // ✅ GUARD 2: التحقق من doctorId
      // =====================================
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
          return;
        }

        // اسم الطبيب (لرسالة الترحيب)
        final doctorSnap = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId!)
            .get();

        doctorName = doctorSnap.data()?['name'];
      } else {
        // مريض
        patientName = data['name'];
      }
    } catch (e) {
      debugPrint('❌ HomeScreen init failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint("Sound error: $e");
    }
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
              icon: const Icon(Icons.language, color: Colors.white),
              tooltip: t.changeLanguage,

              onSelected: (langCode) {
                final langProvider = Provider.of<LanguageProvider>(
                  context,
                  listen: false,
                );

                langProvider.changeLanguage(langCode); // ✅ الحل الحقيقي
              },

              itemBuilder: (context) => [
                const PopupMenuItem(value: 'ar', child: Text('العربية 🇸🇦')),
                const PopupMenuItem(value: 'fr', child: Text('Français 🇫🇷')),
                const PopupMenuItem(value: 'en', child: Text('English 🇬🇧')),
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
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('appointments')
                                .where('patientId', isEqualTo: user!.uid)
                                .where('patientUpdate', isEqualTo: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int count = 0;

                              if (snapshot.hasData) {
                                count = snapshot.data!.docs.length;

                                // ✅ تشغيل الصوت فقط عند ظهور إشعار جديد
                                if (_lastPatientNotif == 0 && count > 0) {
                                  _playNotificationSound();
                                  _shakeController.forward(
                                    from: 0,
                                  ); // ✅ تشغيل الاهتزاز
                                }

                                _lastPatientNotif = count;
                              }

                              return Stack(
                                children: [
                                  /// ✅ زر "مواعيدي"
                                  _ActionButton(
                                    color: brand,
                                    icon: Icons.event_note,
                                    label: t.myAppointments,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MyAppointmentsScreen(),
                                        ),
                                      );
                                    },
                                  ),

                                  /// ✅ الجرس الأحمر
                                  if (count > 0)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          /// ✅ الجرس مع الاهتزاز
                                          AnimatedBuilder(
                                            animation: _shakeController,
                                            builder: (context, child) {
                                              return Transform.rotate(
                                                angle: _shakeAnimation.value,
                                                child: child,
                                              );
                                            },
                                            child: const Icon(
                                              Icons.notifications,
                                              color: Colors.red,
                                              size: 32, // ✅ أكبر قليلاً
                                            ),
                                          ),

                                          /// ✅ الرقم
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.red,
                                                  width: 1.5,
                                                ), // ✅ تحسين
                                              ),
                                              child: Text(
                                                count > 9
                                                    ? '9+'
                                                    : count.toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
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
                          /// ================= DASHBOARD =================
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('appointments')
                                .where('doctorId', isEqualTo: doctorId)
                                .where('doctorUpdate', isEqualTo: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int count = 0;

                              if (snapshot.hasData) {
                                count = snapshot.data!.docs.length;

                                if (_lastDoctorNotif == 0 && count > 0) {
                                  _playNotificationSound();
                                  _shakeController.forward(from: 0);
                                }

                                _lastDoctorNotif = count;
                              }

                              return _ActionButton(
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
                                badge: count > 0 ? _buildBadge(count) : null,
                              );
                            },
                          ),

                          /// ================= SCHEDULE =================
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

                          /// ================= CALENDAR =================
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

                          /// ================= DAYS OFF =================
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

                          /// ================= FINANCE =================
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int count = 0;

                              if (snapshot.hasData &&
                                  snapshot.data!.data() != null) {
                                final data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                final Timestamp? subEnd =
                                    data['subscriptionEnd'];

                                if (subEnd != null) {
                                  final now = DateTime.now().toUtc();
                                  final diff = subEnd
                                      .toDate()
                                      .difference(now)
                                      .inDays;

                                  if (diff <= 7) {
                                    count = 1;
                                  }
                                }
                              }

                              if (_lastSubNotif == 0 && count > 0) {
                                _playNotificationSound();
                                _shakeController.forward(from: 0);
                              }

                              _lastSubNotif = count;

                              return _ActionButton(
                                color: brand,
                                icon: Icons.attach_money,
                                label: t.finance,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const DoctorFinanceScreen(),
                                    ),
                                  );
                                },
                                badge: count > 0 ? _buildBadge(null) : null,
                              );
                            },
                          ),

                          /// ================= SETTINGS =================
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('reports')
                                .where('senderId', isEqualTo: user!.uid)
                                .where('replySeen', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int count = 0;

                              if (snapshot.hasData) {
                                count = snapshot.data!.docs.length;
                                  print("✅ Reports count = $count");
                                if (_lastReportNotif == 0 && count > 0) {
                                  _playNotificationSound();
                                  _shakeController.forward(from: 0);
                                }

                                _lastReportNotif = count;
                              }

                              return _ActionButton(
                                color: brand,
                                icon: Icons.settings,
                                label: t.doctorSettings,

                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const DoctorSettingsScreen(),
                                    ),
                                  );

                                  setState(() {}); // ✅ يجبر إعادة القراءة
                                },

                                badge: count > 0 ? _buildBadge(count) : null,
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

  Widget _buildBadge(int? count) {
    return Positioned(
      top: 6,
      right: 6, // ✅ بدل left (أكثر ثبات)

      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /// 🔔 الجرس
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _shakeAnimation.value,
                child: child,
              );
            },
            child: const Icon(Icons.notifications, color: Colors.red, size: 18),
          ),

          /// ✅ الرقم
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Text(
                count == null ? "!" : (count > 9 ? '9+' : count.toString()),
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkSubscriptionNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    final Timestamp? subEnd = data['subscriptionEnd'];
    final bool alreadySet = data['subscriptionUpdate'] == true;

    if (subEnd != null) {
      final now = DateTime.now().toUtc();
      final diff = subEnd.toDate().difference(now).inDays;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {"subscriptionUpdate": diff <= 7 && diff >= 0},
      );
    }
  }

  @override
  void dispose() {
    _shakeController.dispose(); // ✅ مهم
    _player.dispose(); // ✅ مهم
    super.dispose();
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
    final width = MediaQuery.of(context).size.width;

    return GridView.builder(
      itemCount: children.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,

        // ✅ مهم جدا: نسبة ثابتة (مربعات متناسقة)
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Widget? badge;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16), // ✅ يمنع الخروج

      child: Stack(
        children: [
          /// ✅ الكارت
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // ✅ مهم
                  children: [
                    CircleAvatar(
                      radius: 22, // ✅ نفس الحجم
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, color: color),
                    ),

                    /// ✅ مساحة ثابتة للنص (الحل الحقيقي)
                    SizedBox(
                      height: 40, // ✅ يجبر كل الكروت نفس layout
                      child: Center(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2, // ✅ يمنع stretch
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// ✅ الجرس داخل الكارت (مهم)
          if (badge != null) badge!,
        ],
      ),
    );
  }
}
