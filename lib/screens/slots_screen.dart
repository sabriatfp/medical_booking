import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SlotsScreen extends StatefulWidget {
  final dynamic doctor; // يحتوي على id
  final String date; // yyyy-MM-dd
  final Map<String, dynamic>? scheduleData;

  const SlotsScreen({
    super.key,
    required this.doctor,
    required this.date,
    required this.scheduleData,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  bool _loading = false;

  /// NEW — مجموعة أيام العطل الاستثنائية
  Set<String> _daysOff = {};

  @override
  void initState() {
    super.initState();
    _loadDaysOff();
  }

  /// ✅ تحميل العطل الاستثنائية للطبيب
  Future<void> _loadDaysOff() async {
    final snap = await FirebaseFirestore.instance
        .collection('doctor_days_off')
        .where('doctorId', isEqualTo: widget.doctor.id)
        .get();

    _daysOff = snap.docs.map((d) => (d['date'] as String).trim()).toSet();

    if (mounted) setState(() {});
  }

  /// ✅ دالة تساعد لإيجاد بيانات اليوم المختار من schedule
  Map<String, dynamic>? _findDayData() {
    final weeks = widget.scheduleData?['weeks'];
    if (weeks == null) return null;

    for (var w in weeks) {
      for (var d in w['days']) {
        if ((d['date'] as String).trim() == widget.date) {
          return d;
        }
      }
    }
    return null;
  }

  /// ✅ عرض الساعات من schedule
  List<String> _generateTimes() {
    final day = _findDayData();
    if (day == null) return [];

    final slots = day['slots'];
    if (slots != null && slots is List) {
      return List<String>.from(slots);
    }

    return [];
  }

  /// ✅ تنفيذ عملية الحجز
  Future<void> _bookSlot(String time) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يجب تسجيل الدخول")));
      return;
    }

    final selectedDay = _findDayData();

    // ✅ اليوم يجب أن يكون موجوداً في الجدول
    if (selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا يمكن الحجز في هذا اليوم")),
      );
      return;
    }

    // ✅ منع الحجز في يوم عطلة استثنائية
    if (_daysOff.contains(widget.date)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("هذا اليوم عطلة للطبيب")));
      return;
    }

    // ✅ منع الحجز إذا اليوم غير متاح
    if (selectedDay["available"] != true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("هذا اليوم غير متاح للحجز")));
      return;
    }

    // ✅ منع الحجز إذا اليوم ممتلئ
    if (selectedDay["full"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("هذا اليوم ممتلئ بالكامل")));
      return;
    }

    // ✅ منع حجز وقت غير موجود
    final allowedTimes = List<String>.from(selectedDay["slots"] ?? []);
    if (!allowedTimes.contains(time)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("هذا التوقيت غير متاح")));
      return;
    }

    // ✅ منع الحجز في الماضي
    final selectedDateTime = DateTime.parse("${widget.date} $time");
    if (selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا يمكن الحجز في وقت ماضي")),
      );
      return;
    }

    setState(() => _loading = true);

    final fs = FirebaseFirestore.instance;

    final slotId = "${widget.doctor.id}_${widget.date}_$time";
    final slotRef = fs.collection('doctor_slots').doc(slotId);
    final appointmentRef = fs.collection('appointments').doc();

    try {
      await fs.runTransaction((t) async {
        final slotSnap = await t.get(slotRef);

        // ✅ لا يمكن الحجز إذا كان التوقيت محجوز مسبقًا
        if (slotSnap.exists) {
          final data = slotSnap.data();
          if (data != null && data['taken'] == true) {
            throw Exception("taken");
          }
        }

        // ✅ حماية إضافية ضد bypass
        if (!allowedTimes.contains(time)) {
          throw Exception("invalid_slot");
        }

        // ✅ إنشاء / تحديث slot
        t.set(slotRef, {
          "doctorId": widget.doctor.id,
          "date": widget.date,
          "time": time,
          "taken": true,
          "patientId": user.uid,
        }, SetOptions(merge: true));

        // ✅ إنشاء appointment
        t.set(appointmentRef, {
          "doctorId": widget.doctor.id,
          "patientId": user.uid,

          "doctorName": widget.doctor.name ?? "",
          "doctorSpecialty": widget.doctor.specialty ?? "",

          "patientName": user.displayName ?? "",
          "patientPhone": user.phoneNumber ?? "",

          "dateTime": Timestamp.fromDate(selectedDateTime),
          "slotId": slotId,
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إرسال طلب الحجز بنجاح ✔")),
      );
    } catch (e) {
      String message = "حدث خطأ غير متوقع";

      if (e.toString().contains("taken")) {
        message = "هذا الموعد محجوز بالفعل ❌";
      } else if (e.toString().contains("invalid_slot")) {
        message = "لا يمكن حجز وقت غير موجود في جدول الطبيب";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final times = _generateTimes();

    return Scaffold(
      appBar: AppBar(title: const Text("اختيار موعد")),
      body: Stack(
        children: [
          GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: times.length,
            itemBuilder: (context, index) {
              final time = times[index];

              return ElevatedButton(
                onPressed: _loading ? null : () => _bookSlot(time),
                child: Text(time),
              );
            },
          ),

          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
