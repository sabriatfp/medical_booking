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

  Map<String, dynamic>? doctorData;

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

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    doctorId = userDoc.data()?['doctorId'];

    if (doctorId == null) {
      setState(() => loading = false);
      return;
    }

    final doctorSnap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    doctorData = doctorSnap.data();

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    totalRevenue = 0;
    monthlyRevenue = 0;
    todayRevenue = 0;
    confirmedAppointments = 0;
    cancelledAppointments = 0;

    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    for (var doc in snap.docs) {
      final data = doc.data();

      final status = data['status'] ?? 'confirmed';

      final price = (data['price'] is num)
          ? (data['price'] as num).toDouble()
          : 0.0;

      final date = DateTime.tryParse(data['date'] ?? '');

      if (date == null) continue;

      if (status == 'cancelled') {
        cancelledAppointments++;
        continue;
      }

      if (status == 'confirmed') {
        confirmedAppointments++;
        totalRevenue += price;

        if (date.year == now.year && date.month == now.month) {
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
              /// 🧾 الاشتراك
              /// =======================
              _sectionTitle("الاشتراك"),
              const SizedBox(height: 12),

              _subscriptionCard(),

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

  Widget _subscriptionCard() {
    final now = DateTime.now();

    DateTime? subscriptionEnd = (doctorData?['subscriptionEnd'] as Timestamp?)
        ?.toDate();

    DateTime? trialEnd = (doctorData?['trialEnd'] as Timestamp?)?.toDate();

    String status;
    Color color;
    DateTime? endDate;

    if (subscriptionEnd != null && subscriptionEnd.isAfter(now)) {
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
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
            if (daysLeft > 0) Text("متبقي $daysLeft يوم"),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // لاحقاً بوابة الدفع
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
