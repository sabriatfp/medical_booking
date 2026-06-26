import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

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

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchFinanceData();
  }

  Future<void> fetchFinanceData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      userData = userDoc.data();
      doctorId = userData?['doctorId'];

      if (doctorId == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final now = DateTime.now();

      totalRevenue = 0;
      monthlyRevenue = 0;
      todayRevenue = 0;
      confirmedAppointments = 0;
      cancelledAppointments = 0;

      // ✅ 1️⃣ جلب العمليات المالية (Check‑in فقط)
      final txSnap = await FirebaseFirestore.instance
          .collection('financial_transactions')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'paid')
          .get();

      for (var doc in txSnap.docs) {
        final data = doc.data();

        final amount = (data['amount'] is num)
            ? (data['amount'] as num).toDouble()
            : 0.0;

        totalRevenue += amount;

        final Timestamp? ts = data['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final date = ts.toDate();

        if (date.year == now.year && date.month == now.month) {
          monthlyRevenue += amount;
        }

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          todayRevenue += amount;
        }

        confirmedAppointments++; // ✅ عدد المرضى الذين حضروا
      }

      // ✅ 2️⃣ عدد المواعيد الملغاة (اختياري – ليس ماليًا)
      final cancelledSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'canceled')
          .get();

      cancelledAppointments = cancelledSnap.size;
    } catch (e) {
      debugPrint("❌ Finance load failed: $e");
    } finally {
      // ✅✅✅ هذا هو السطر الذي كان ناقصًا
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (doctorId == null) {
      return Scaffold(body: Center(child: Text(t.doctorIdNotFound)));
    }

    return WillPopScope(
      onWillPop: () async {
        _clearSubscriptionUpdate();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(t.financeDashboard), centerTitle: true),

        body: RefreshIndicator(
          onRefresh: fetchFinanceData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 💰 الملخص المالي
                _sectionTitle(t.revenueSummary),
                const SizedBox(height: 12),

                Row(
                  children: [
                    statCard(
                      title: t.todayRevenue,
                      value: "${todayRevenue.toStringAsFixed(0)} د",
                      icon: Icons.today,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    statCard(
                      title: t.monthRevenue,
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
                      title: t.totalRevenue,
                      value: "${totalRevenue.toStringAsFixed(0)} د",
                      icon: Icons.attach_money,
                      color: Colors.teal,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// 📊 أداء المواعيد
                _sectionTitle(t.appointmentPerformance),
                const SizedBox(height: 12),

                Row(
                  children: [
                    statCard(
                      title: t.confirmedAppointments,
                      value: "$confirmedAppointments",
                      icon: Icons.check_circle,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    statCard(
                      title: t.cancelledAppointments,
                      value: "$cancelledAppointments",
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                _successRateCard(),

                const SizedBox(height: 30),

                /// 🧾 الاشتراك
                Stack(
                  children: [
                    _sectionTitle(t.subscription),

                    if (userData?['subscriptionUpdate'] == true)
                      Positioned(
                        top: -3,
                        left: -12,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                _subscriptionCard(),

                const SizedBox(height: 30),

                Center(
                  child: Text(
                    "${t.lastUpdate}: ${DateFormat('dd MMM yyyy - HH:mm').format(DateTime.now())}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
    final t = AppLocalizations.of(context)!;

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
            Text(t.successRate, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// بطاقة الاشتراك
  Widget _subscriptionCard() {
    final t = AppLocalizations.of(context)!;

    final now = DateTime.now().toUtc();

    final active = (userData?['subscriptionActive'] ?? false) == true;
    final Timestamp? subEndTs = userData?['subscriptionEnd'] as Timestamp?;
    final DateTime? subscriptionEnd = subEndTs?.toDate();

    final Timestamp? trialTs = userData?['trialEnd'] as Timestamp?;
    final DateTime? trialEnd = trialTs?.toDate();

    String status;
    Color color;
    DateTime? endDate;

    if (active && subscriptionEnd != null && subscriptionEnd.isAfter(now)) {
      status = t.subscriptionActive;
      color = Colors.green;
      endDate = subscriptionEnd;
    } else if (trialEnd != null && trialEnd.isAfter(now)) {
      status = t.subscriptionTrial;
      color = Colors.orange;
      endDate = trialEnd;
    } else {
      status = t.subscriptionExpired;
      color = Colors.red;
    }

    final daysLeft = endDate != null ? endDate.difference(now).inDays : 0;
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
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.subscriptionExpiringSoon)),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    t.subscriptionStatus,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (endDate != null)
              Text(
                "${t.subscriptionEndsAt}: ${DateFormat('yyyy-MM-dd').format(endDate)}",
              ),

            if (endDate != null && endDate.isAfter(now) && daysLeft > 0)
              Text(t.remainingDays(daysLeft)),

            const SizedBox(height: 14),

            if (status == t.subscriptionExpired || expiringSoon)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    final db = FirebaseFirestore.instance;

                    await db.collection('subscription_requests').add({
                      'doctorUid': user.uid,
                      'doctorId': userData?['doctorId'],
                      'doctorName': userData?['name'] ?? '',
                      'email': userData?['email'] ?? '',
                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.subscriptionRequestSent)),
                    );
                  },
                  child: Text(t.renewSubscription),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearSubscriptionUpdate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      "subscriptionUpdate": false,
    });
  }
}
