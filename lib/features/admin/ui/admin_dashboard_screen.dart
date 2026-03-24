import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:medical_booking/features/admin/ui/admin_subscriptions_screen.dart';
import 'package:medical_booking/features/admin/ui/admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loadingRole = true;
  bool _isAdmin = false;
  String? _uid;

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على مستخدم مسجّل الدخول'),
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // ✅ نقرأ من السيرفر لتفادي الكاش بعد تغيير الدور
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));

      final role = snap.data()?['role'];
      // الطباعة كما طلبت (مع uid)
      // مثال: ADMIN CHECK → uid=..., role=admin
      //       ADMIN CHECK → uid=..., role=doctor
      // ستساعد في التشخيص
      // ignore: avoid_print
      print('ADMIN CHECK → uid=$uid, role=$role');

      setState(() {
        _loadingRole = false;
        _isAdmin = role == 'admin';
      });

      if (!_isAdmin && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('صلاحيات غير كافية: هذا القسم مخصص للأدمن'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // ignore: avoid_print
      print('ADMIN CHECK ERROR → $e');
      setState(() {
        _loadingRole = false;
        _isAdmin = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فحص صلاحيات الأدمن. حاول مجددًا.'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // ignore: avoid_print
      print('SIGN OUT ERROR → $e');
    }
    if (!mounted) return;
    // لو عندك Route محدد لتسجيل الدخول استخدم pushNamedAndRemoveUntil
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  /// زر “مزامنة الاشتراكات”:
  /// يبني/يحدّث doctor_subscriptions/{doctorId} من users/{doctorUid}
  /// بحيث لا تتكرر مشكلة الSnackbar عند المرضى.
  Future<void> _syncDoctorSubscriptions() async {
    if (!_isAdmin) return;
    if (!mounted) return;

    final db = FirebaseFirestore.instance;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    int processed = 0;
    int updated = 0;
    try {
      // نقرأ من السيرفر لتكون القيم حديثة
      final usersSnap = await db
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get(const GetOptions(source: Source.server));

      final batch = db.batch();

      for (final doc in usersSnap.docs) {
        processed++;
        final data = doc.data();

        final String? doctorId = data['doctorId'] as String?;
        if (doctorId == null || doctorId.isEmpty) continue;

        final bool active = (data['subscriptionActive'] == true);
        final Timestamp? endTs = data['subscriptionEnd'] as Timestamp?;
        final String? plan = data['subscriptionPlan'] as String?;

        final subRef = db.collection('doctor_subscriptions').doc(doctorId);
        batch.set(subRef, {
          'active': active,
          'end': endTs,
          if (plan != null) 'plan': plan,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        updated++;
        // نفذ على دفعات لتجنب تجاوز حدود حجم الدُفعة
        if (updated % 400 == 0) {
          await batch.commit();
        }
      }

      // إن لم نصل 400 فلن تُنفّذ commit، لذا:
      await batch.commit();

      if (!mounted) return;
      Navigator.of(context).pop(); // أغلق Dialog

      messenger.showSnackBar(
        SnackBar(
          content: Text('تمت مزامنة الاشتراكات: $updated / $processed طبيب'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('فشل المزامنة: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = <_AdminEntry>[
      _AdminEntry(
        icon: Icons.verified_user,
        title: 'إدارة اشتراكات الأطباء',
        subtitle: 'تفعيل/تعطيل وتحديد تاريخ الانتهاء',
        builder: (_) => const AdminSubscriptionsScreen(),
      ),
      _AdminEntry(
        icon: Icons.report,
        title: 'البلاغات',
        subtitle: 'عرض ومعالجة البلاغات الواردة',
        builder: (_) => const AdminReportsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        actions: [
          // قائمة أدوات أدمن صغيرة
          if (_isAdmin)
            PopupMenuButton<String>(
              tooltip: 'أدوات',
              onSelected: (value) {
                if (value == 'sync') {
                  _syncDoctorSubscriptions();
                } else if (value == 'logout') {
                  _signOut(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'sync',
                  child: Text('مزامنة اشتراكات الأطباء (doctor_subscriptions)'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('تسجيل الخروج'),
                ),
              ],
            )
          else
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
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
                  : null, // حماية إضافية
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
