// lib/features/admin/ui/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:medical_booking/features/admin/ui/admin_subscriptions_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_reports_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_subscription_requests_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'admin_maintenance_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loadingRole = true;
  bool _isAdmin = false;
  String? _uid;
  bool _syncing = false;
  bool _permissionHandled = false;
  int _lastAdminCount = 0;
  int _lastReportsCount = 0;
  int _maintenanceTapCount = 0;
  DateTime? _firstTapTime;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  void _handleMaintenanceTap() {
    if (!_isAdmin) return; // ✅ حماية مهمة

    final now = DateTime.now();

    if (_firstTapTime == null || now.difference(_firstTapTime!).inSeconds > 3) {
      _firstTapTime = now;
      _maintenanceTapCount = 1;
    } else {
      _maintenanceTapCount++;
    }
    if (_maintenanceTapCount == 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("🔐 Secret mode...")));
    }

    if (_maintenanceTapCount >= 5) {
      _maintenanceTapCount = 0;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminMaintenanceScreen()),
      );
    }
  }

  Future<void> _checkAdminRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      _uid = uid;

      if (uid == null) {
        setState(() {
          _loadingRole = false;
          _isAdmin = false;
        });
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final role = snap.data()?['role'];

      print('ADMIN CHECK → uid=$uid, role=$role');

      setState(() {
        _loadingRole = false;
        _isAdmin = role == 'admin';
      });
    } catch (e) {
      print('ADMIN CHECK ERROR → $e');

      setState(() {
        _loadingRole = false;
        _isAdmin = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("SIGN OUT ERROR → $e");
    }
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAdmin && !_permissionHandled) {
      _permissionHandled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.insufficientPermissions)));
        Navigator.of(context).pop();
      });

      return const Scaffold();
    }

    final List<_AdminEntry> items = [
      _AdminEntry(
        icon: Icons.verified_user,
        title: t.manageSubscriptions,
        subtitle: t.manageSubscriptionsSubtitle,
        builder: (_) => const AdminSubscriptionsScreen(),
      ),

      // ✅✅✅ طلبات تجديد الاشتراك
      _AdminEntry(
        icon: Icons.notifications_active,
        title: t.subscriptionRequests,
        subtitle: t.subscriptionRequestsSubtitle,
        builder: (_) => const AdminSubscriptionRequestsScreen(),
      ),

      _AdminEntry(
        icon: Icons.report,
        title: t.reports,
        subtitle: t.reportsSubtitle,
        builder: (_) => const AdminReportsScreen(),
      ),
      _AdminEntry(
        icon: Icons.build,
        title: t.systemTools,
        subtitle: t.systemToolsSubtitle,
        builder: (_) => const SizedBox(), // لن نستعمله
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminDashboard),

        actions: [
          /// ✅ زر الترجمة
          IconButton(
            tooltip: t.changeLanguage,
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageDialog(context),
          ),

          /// ✅ تسجيل الخروج
          IconButton(
            tooltip: t.logout,
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),

        itemBuilder: (_, index) {
          final it = items[index];
          final isMaintenance = it.title == t.systemTools;

          /// ✅ إذا هذا هو كارت الطلبات
          final isRequests = it.title == t.subscriptionRequests;
          final isReports = it.title == t.reports;
          if (isRequests || isReports) {
            return StreamBuilder<QuerySnapshot>(
              stream: isReports
                  ? FirebaseFirestore.instance
                        .collection('reports')
                        .where('status', isEqualTo: 'new')
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('subscription_requests')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
              builder: (context, snapshot) {
                int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

                /// ✅ تشغيل الصوت عند زيادة الطلبات
                if (isReports) {
                  if (_lastReportsCount == 0 && count > 0) {
                    _playNotificationSound();
                  }

                  if (count > _lastReportsCount) {
                    _playNotificationSound();
                  }

                  _lastReportsCount = count;
                } else {
                  if (_lastAdminCount == 0 && count > 0) {
                    _playNotificationSound();
                  }

                  if (count > _lastAdminCount) {
                    _playNotificationSound();
                  }

                  _lastAdminCount = count;
                }

                return Card(
                  elevation: 1.5,
                  child: Stack(
                    children: [
                      /// ✅ الكارت
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(it.icon, color: Colors.teal),
                        ),
                        title: Text(
                          it.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(it.subtitle),

                        /// ✅ السهم فقط
                        trailing: const Icon(Icons.chevron_right),

                        onTap: () {
                          _handleMaintenanceTap();

                          if (_isAdmin) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: it.builder),
                            );
                          }
                        },
                      ),

                      /// ✅ ✅ الجرس
                      if (count > 0)
                        Positioned(
                          right: 32,
                          top: 10,
                          child: _adminBadge(count),
                        ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Card(
              elevation: 1.5,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(it.icon, color: Colors.teal),
                ),
                title: Text(
                  it.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(it.subtitle),
                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  /// ✅ هذا هو الكارت السري
                  if (isMaintenance) {
                    _handleMaintenanceTap();
                    return;
                  }

                  /// ✅ باقي الكروت تشتغل عادي
                  if (_isAdmin) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: it.builder),
                    );
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> _playNotificationSound() async {
    try {
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint("Sound error: $e");
    }
  }

  Widget _adminBadge(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications, color: Colors.red, size: 20),
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
              count > 9 ? '9+' : count.toString(),
              style: const TextStyle(
                fontSize: 9,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            t.chooseLanguage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🇸🇦 العربية
            TextButton(
              onPressed: () {
                provider.changeLanguage('ar');
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [const Text("🇸🇦 "), Text(t.arabic)],
              ),
            ),

            /// 🇫🇷 الفرنسية
            TextButton(
              onPressed: () {
                provider.changeLanguage('fr');
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [const Text("🇫🇷 "), Text(t.french)],
              ),
            ),

            /// 🇬🇧 الإنجليزية
            TextButton(
              onPressed: () {
                provider.changeLanguage('en');
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [const Text("🇬🇧 "), Text(t.english)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  _AdminEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });
}
