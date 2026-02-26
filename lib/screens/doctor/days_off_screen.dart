import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_service.dart';

class DaysOffScreen extends StatefulWidget {
  const DaysOffScreen({super.key});

  @override
  State<DaysOffScreen> createState() => _DaysOffScreenState();
}

class _DaysOffScreenState extends State<DaysOffScreen> {
  final DoctorService _doctorService = DoctorService();

  DateTime? startDate;
  DateTime? endDate;
  String? doctorId;
  bool loadingDoctor = true;
  final reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDoctorId();
  }

  Future<void> loadDoctorId() async {
    doctorId = await _doctorService.getDoctorId();
    setState(() => loadingDoctor = false);
  }

  Future<void> pickDateRange() async {
    final now = DateTime.now();

    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      locale: const Locale('ar'),
    );

    if (range == null) return;

    startDate = range.start;
    endDate = range.end;
    setState(() {});
  }

  Future<void> saveDaysOff() async {
    if (startDate == null || endDate == null || doctorId == null) return;

    DateTime current = startDate!;

    while (!current.isAfter(endDate!)) {
      final dateStr =
          "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";

      final dayOffRef = FirebaseFirestore.instance
          .collection('doctor_days_off')
          .doc();

      final batch = FirebaseFirestore.instance.batch();

      // إضافة يوم الغياب
      batch.set(dayOffRef, {
        "doctorId": doctorId,
        "date": dateStr,
        "reason": reasonController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      // إلغاء المواعيد في نفس اليوم
      final appointmentsSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: dateStr)
          .where('status', isNotEqualTo: 'canceled')
          .get();

      for (var doc in appointmentsSnap.docs) {
        final slotId = doc.data()['slotId'];
        batch.update(doc.reference, {"status": "canceled"});

        if (slotId != null) {
          final slotRef = FirebaseFirestore.instance
              .collection('doctor_slots')
              .doc(slotId);
          batch.update(slotRef, {"taken": false});
        }
      }

      await batch.commit();
      current = current.add(const Duration(days: 1));
    }

    reasonController.clear();
    setState(() {
      startDate = null;
      endDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم حفظ أيام الغياب وإلغاء المواعيد المتعارضة"),
      ),
    );
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingDoctor) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("أيام الغياب")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextButton.icon(
              onPressed: pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                startDate == null
                    ? "اختيار فترة الغياب"
                    : "من ${startDate!.day}/${startDate!.month} إلى ${endDate!.day}/${endDate!.month}",
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "سبب الغياب (اختياري)",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: saveDaysOff, child: const Text("حفظ")),
            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "أيام الغياب المسجلة:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctor_days_off')
                    .where('doctorId', isEqualTo: doctorId)
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("لا توجد أيام غياب مسجلة"));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      return ListTile(
                        title: Text(d['date']),
                        subtitle: Text(d['reason'] ?? ""),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            if (doctorId == null) return;

                            final dateStr = d['date'];
                            final batch = FirebaseFirestore.instance.batch();

                            // حذف يوم الغياب
                            batch.delete(d.reference);

                            // إعادة فتح slots لذلك اليوم
                            final slotsSnap = await FirebaseFirestore.instance
                                .collection('doctor_slots')
                                .where('doctorId', isEqualTo: doctorId)
                                .where('date', isEqualTo: dateStr)
                                .get();

                            for (var slot in slotsSnap.docs) {
                              batch.update(slot.reference, {"taken": false});
                            }

                            await batch.commit();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "تم حذف يوم الغياب وإعادة فتح المواعيد",
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
