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
  /// فحص دور المستخدم في initState + طباعة المطلوب للكونسول
  @override
  void initState() {
    super.initState();

    // ننفّذ بعد أول frame حتى يكون الـ context جاهز لأي UI feedback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        final role = snap.data()?['role'];
        // الطباعة التي طلبتها حرفيًا:
        print('ADMIN CHECK → uid=$uid, role=$role');

        // (اختياري لكن مفيد) في حال لم يكن Admin، نعيد المستخدم للخلف برسالة
        if (role != 'admin') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('صلاحيات غير كافية: هذا القسم مخصص للأدمن'),
              ),
            );
            Navigator.of(context).pop(); // ارجع للشاشة السابقة
          }
        }
      } catch (e) {
        // طباعة الخطأ للديبَغ
        print('ADMIN CHECK ERROR → $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر فحص صلاحيات الأدمن. حاول مجددًا.'),
            ),
          );
        }
      }
    });
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // ارجع لشاشة الدخول العامة
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: it.builder),
              ),
            ),
          );
        },
      ),
      // اختيارياً: Drawer إن حبيت
      // drawer: _AdminDrawer(items: items),
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
