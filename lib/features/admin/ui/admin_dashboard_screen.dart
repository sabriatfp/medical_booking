// lib/features/admin/ui/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:medical_booking/features/admin/ui/admin_subscriptions_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_reports_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_subscription_requests_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
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
          .get(const GetOptions(source: Source.server));

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
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminDashboard),

        actions: [
          // ✅ زر تسجيل الخروج (للجميع)
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
              onTap: _isAdmin
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: it.builder),
                    )
                  : null,
            ),
          );
        },
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
