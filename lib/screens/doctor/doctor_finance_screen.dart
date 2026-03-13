import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoctorFinanceScreen extends StatefulWidget {
  const DoctorFinanceScreen({super.key});

  @override
  State<DoctorFinanceScreen> createState() => _DoctorFinanceScreenState();
}

class _DoctorFinanceScreenState extends State<DoctorFinanceScreen> {
  String? doctorId;
  bool loading = true;

  double totalRevenue = 0;
  double monthlyRevenue = 0;
  double todayRevenue = 0;

  int confirmedAppointments = 0;
  int cancelledAppointments = 0;

  Map<String, dynamic>? userData; // ← مصدر الاشتراك الجديد

  @override
  void initState() {
    super.initState();
    fetchFinanceData();
  }

  Future<void> fetchFinanceData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

    // 1) جلب وثيقة المستخدم (users/{uid})
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    userData = userDoc.data();

    doctorId = userData?['doctorId'];

    if (doctorId == null) {
      setState(() => loading = false);
      return;
    }

    // 2) إعادة تهيئة القيم
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    totalRevenue = 0;
    monthlyRevenue = 0;
    todayRevenue = 0;
    confirmedAppointments = 0;
    cancelledAppointments = 0;

    // 3) قراءة المواعيد الخاصة بالطبيب وحساب الملخّص
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    for (var doc in snap.docs) {
      final data = doc.data();

      final rawStatus = (data['status'] ?? 'confirmed')
          .toString()
          .toLowerCase();
      // دعم التهجئتين 'canceled' و 'cancelled'
      final isCanceled = rawStatus == 'canceled' || rawStatus == 'cancelled';
      final isConfirmed = rawStatus == 'confirmed';

      final price = (data['price'] is num)
          ? (data['price'] as num).toDouble()
          : 0.0;

      // أغلب الشاشات لديك تعتمد على تاريخ كنص في الحقل 'date'
      final date = DateTime.tryParse(data['date'] ?? '');

      if (date == null) continue;

      if (isCanceled) {
        cancelledAppointments++;
        continue;
      }

      if (isConfirmed) {
        confirmedAppointments++;
        totalRevenue += price;

        if (date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
            date.month == now.month &&
            date.year == now.year) {
          monthlyRevenue += price;
        }

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          todayRevenue += price;
        }
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (doctorId == null) {
      return const Scaffold(
        body: Center(child: Text("لم يتم العثور على معرف الطبيب")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("اللوحة المالية"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: fetchFinanceData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// =======================
              /// 💰 ملخص الأرباح
              /// =======================
              _sectionTitle("ملخص الأرباح"),
              const SizedBox(height: 12),

              Row(
                children: [
                  statCard(
                    title: "دخل اليوم",
                    value: "${todayRevenue.toStringAsFixed(0)} د",
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  statCard(
                    title: "دخل الشهر",
                    value: "${monthlyRevenue.toStringAsFixed(0)} د",
                    icon: Icons.calendar_month,
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  statCard(
                    title: "إجمالي الأرباح",
                    value: "${totalRevenue.toStringAsFixed(0)} د",
                    icon: Icons.attach_money,
                    color: Colors.teal,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// =======================
              /// 📊 أداء المواعيد
              /// =======================
              _sectionTitle("أداء المواعيد"),
              const SizedBox(height: 12),

              Row(
                children: [
                  statCard(
                    title: "المؤكدة",
                    value: "$confirmedAppointments",
                    icon: Icons.check_circle,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  statCard(
                    title: "الملغاة",
                    value: "$cancelledAppointments",
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _successRateCard(),

              const SizedBox(height: 30),

              /// =======================
              /// 🧾 الاشتراك (من users/{uid})
              /// =======================
              _sectionTitle("الاشتراك"),
              const SizedBox(height: 12),

              _subscriptionCard(), // ← الآن يقرأ من userData

              const SizedBox(height: 30),

              Center(
                child: Text(
                  "آخر تحديث: ${DateFormat('dd MMM yyyy - HH:mm', 'ar').format(DateTime.now())}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ===============================
  /// Widgets
  /// ===============================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successRateCard() {
    final total = confirmedAppointments + cancelledAppointments;
    final rate = total == 0 ? 0 : (confirmedAppointments / total) * 100;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.bar_chart, color: Colors.purple, size: 28),
            const SizedBox(height: 10),
            Text(
              "${rate.toStringAsFixed(0)}%",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text("نسبة النجاح", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// بطاقة الاشتراك — الآن من users/{uid}
  Widget _subscriptionCard() {
    final now = DateTime.now();

    // قراءة الحقول من وثيقة المستخدم
    final active = (userData?['subscriptionActive'] ?? false) == true;
    final Timestamp? subEndTs = userData?['subscriptionEnd'] as Timestamp?;
    final DateTime? subscriptionEnd = subEndTs?.toDate();

    final Timestamp? trialTs = userData?['trialEnd'] as Timestamp?;
    final DateTime? trialEnd = trialTs?.toDate();

    String status;
    Color color;
    DateTime? endDate;

    // منطق الحالة:
    // 1) إن كان active=true و subscriptionEnd في المستقبل ⇒ نشط
    // 2) وإلا إن كان trialEnd في المستقبل ⇒ تجريبي
    // 3) غير ذلك ⇒ منتهي
    if (active && subscriptionEnd != null && subscriptionEnd.isAfter(now)) {
      status = "نشط";
      color = Colors.green;
      endDate = subscriptionEnd;
    } else if (trialEnd != null && trialEnd.isAfter(now)) {
      status = "تجريبي";
      color = Colors.orange;
      endDate = trialEnd;
    } else {
      status = "منتهي";
      color = Colors.red;
    }

    final daysLeft = endDate != null ? endDate.difference(now).inDays : 0;

    // شارة تنبيه في حالة اقتراب الانتهاء
    final bool expiringSoon =
        endDate != null &&
        endDate.isAfter(now) &&
        endDate.difference(now).inDays <= 7;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (expiringSoon)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text("ينتهي الاشتراك قريبًا — يُنصح بالتجديد."),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("حالة الاشتراك", style: TextStyle(fontSize: 16)),
                Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (endDate != null)
              Text("ينتهي في: ${DateFormat('yyyy-MM-dd').format(endDate)}"),
            if (endDate != null && endDate.isAfter(now) && daysLeft > 0)
              Text("متبقي $daysLeft يوم"),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // لاحقًا: ربط بوابة الدفع أو إرسال طلب للأدمن
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("سيتم إضافة بوابة الدفع لاحقًا."),
                    ),
                  );
                },
                child: const Text("تجديد الاشتراك"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
