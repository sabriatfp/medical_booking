import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor.dart';

class SlotsScreen extends StatefulWidget {
  final Doctor doctor;
  final String date;
  final Map<String, dynamic> schedule;

  const SlotsScreen({
    super.key,
    required this.doctor,
    required this.date,
    required this.schedule,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  List<String> slots = [];
  List<String> booked = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSlots();
  }

  // توليد الفترات الزمنية
  List<String> generateDailySlots(String start, String end, int slotMinutes) {
    List<String> out = [];

    final s = start.split(":");
    final e = end.split(":");

    int startMin = int.parse(s[0]) * 60 + int.parse(s[1]);
    int endMin = int.parse(e[0]) * 60 + int.parse(e[1]);

    int current = startMin;

    while (current + slotMinutes <= endMin) {
      final h = (current ~/ 60).toString().padLeft(2, '0');
      final m = (current % 60).toString().padLeft(2, '0');
      out.add("$h:$m");
      current += slotMinutes;
    }

    return out;
  }

  Future<void> loadSlots() async {
    final allWeeks = widget.schedule['weeks'] as List;
    final slotDuration = widget.schedule['slotDuration'];

    Map<String, dynamic>? dayData;

    for (var w in allWeeks) {
      for (var d in w["days"]) {
        if (d["date"].toString().trim() == widget.date.trim()) {
          dayData = d;
          break;
        }
      }
    }

    if (dayData == null || dayData["available"] == false) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }

    slots = generateDailySlots(dayData["start"], dayData["end"], slotDuration);

    await loadBookedSlots();

    if (!mounted) return;
    setState(() => loading = false);
  }

  // جلب المحجوز
  Future<void> loadBookedSlots() async {
    final q = await FirebaseFirestore.instance
        .collection('doctor_slots')
        .where('doctorId', isEqualTo: widget.doctor.id)
        .where('date', isEqualTo: widget.date)
        .where('taken', isEqualTo: true)
        .get();

    booked = q.docs.map((d) => d['time'] as String).toList();
  }

  Future<bool> isSubscriptionActive(String doctorId) async {
    final doctorSnap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();

    final data = doctorSnap.data();
    if (data == null) return false;

    final now = DateTime.now();

    final subscriptionEnd = (data['subscriptionEnd'] as Timestamp?)?.toDate();

    final trialEnd = (data['trialEnd'] as Timestamp?)?.toDate();

    if (subscriptionEnd != null && subscriptionEnd.isAfter(now)) {
      return true;
    }

    if (trialEnd != null && trialEnd.isAfter(now)) {
      return true;
    }

    return false;
  }

  // الحجز
  Future<void> book(String time) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final date = DateTime.parse(widget.date);
    final parts = time.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final dt = DateTime(date.year, date.month, date.day, hour, minute);

    final slotId = "${widget.doctor.id}_${widget.date}_$time";
    final slotRef = FirebaseFirestore.instance
        .collection('doctor_slots')
        .doc(slotId);

    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userSnap.data();
    final patientName = data?['name'] ?? '';
    final patientPhone = data?['phone'] ?? '';
    // 🔴 التحقق من الاشتراك
    final active = await isSubscriptionActive(widget.doctor.id);

    if (!active) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("لا يمكن الحجز حالياً. اشتراك الطبيب منتهي."),
        ),
      );
      return;
    }

    try {
      // 🔴 1️⃣ تحقق خارج الـ transaction
      final existing = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('doctorId', isEqualTo: widget.doctor.id) // ✅ جديد
          .where('date', isEqualTo: widget.date)
          .where('status', whereIn: ['pending', 'confirmed']) // أفضل من !=
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception("already-booked");
      }

      await FirebaseFirestore.instance
          .runTransaction((t) async {
            final doctorRef = FirebaseFirestore.instance
                .collection('doctors')
                .doc(widget.doctor.id);

            final doctorSnap = await t.get(doctorRef);
            final currentPrice = (doctorSnap.data()?['price'] ?? 0).toDouble();
            // 2️⃣ تحقق أن الـ slot غير محجوز
            final slotSnap = await t.get(slotRef);

            if (slotSnap.exists && slotSnap['taken'] == true) {
              throw Exception("taken");
            }

            // 3️⃣ حدّث فقط taken
            t.set(slotRef, {
              "doctorId": widget.doctor.id,
              "date": widget.date,
              "time": time,
              "taken": true,
            });

            // 4️⃣ إنشاء الموعد
            final appointmentRef = FirebaseFirestore.instance
                .collection('appointments')
                .doc();

            t.set(appointmentRef, {
              "appointmentId": appointmentRef.id,
              "doctorId": widget.doctor.id,
              "doctorName": widget.doctor.name,
              "patientId": user.uid,
              "patientName": patientName,
              "patientPhone": patientPhone,
              "date": widget.date,
              "time": time,
              "dateTime": Timestamp.fromDate(dt),
              "price": currentPrice,
              "status": "pending",
              "slotId": slotId,
              "createdAt": FieldValue.serverTimestamp(),
            });
          })
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إرسال طلب الحجز بنجاح ✔")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      String msg = "حدث خطأ غير متوقع";

      if (e.toString().contains("taken")) {
        msg = "هذا التوقيت محجوز مسبقًا";
      } else if (e.toString().contains("already-booked")) {
        msg = "لديك موعد آخر في نفس اليوم";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("المواعيد المتاحة – ${widget.date}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: slots.isEmpty
            ? const Center(child: Text("لا توجد مواعيد متوفرة في هذا اليوم"))
            : ListView(
                children: slots.map((slot) {
                  final taken = booked.contains(slot);

                  return Card(
                    color: taken ? Colors.grey.shade300 : Colors.white,
                    child: ListTile(
                      title: Text(slot),
                      trailing: taken
                          ? const Text(
                              "محجوز",
                              style: TextStyle(color: Colors.red),
                            )
                          : ElevatedButton(
                              onPressed: () => book(slot),
                              child: const Text("احجز"),
                            ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
