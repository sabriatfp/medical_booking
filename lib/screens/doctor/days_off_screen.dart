// lib/screens/doctor/days_off_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_service.dart';

class DaysOffScreen extends StatefulWidget {
  final String? doctorId;
  final bool asSecretary;
  final bool hideInnerHeader;

  const DaysOffScreen({
    super.key,
    this.doctorId,
    this.asSecretary = false,
    this.hideInnerHeader = false,
  });

  @override
  State<DaysOffScreen> createState() => _DaysOffScreenState();
}

class _DaysOffScreenState extends State<DaysOffScreen> {
  final DoctorService _doctorService = DoctorService();

  String? _resolvedDoctorId;
  bool _loadingDoctor = true;
  String? _error;

  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _resolveDoctorId();
  }

  Future<void> _resolveDoctorId() async {
    try {
      if (widget.doctorId != null && widget.doctorId!.isNotEmpty) {
        _resolvedDoctorId = widget.doctorId;
      } else {
        _resolvedDoctorId = await _doctorService.getDoctorId();
      }

      if (_resolvedDoctorId == null || _resolvedDoctorId!.isEmpty) {
        _error = 'لم يتم العثور على معرف الطبيب';
      }
    } catch (e) {
      _error = 'خطأ أثناء تحديد الطبيب';
    } finally {
      if (mounted) setState(() => _loadingDoctor = false);
    }
  }

  // ✅ اختيار فترة الغياب
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      locale: const Locale('ar'),
    );

    if (range == null) return;

    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
  }

  // ✅ حفظ أيام الغياب + إلغاء المواعيد المتعارضة
  Future<void> _saveDaysOff() async {
    final doctorId = _resolvedDoctorId;

    if (doctorId == null || _startDate == null || _endDate == null) return;

    final fs = FirebaseFirestore.instance;
    final batch = fs.batch();

    DateTime current = _startDate!;
    final reason = _reasonController.text.trim();

    List<String> addedDates = [];

    while (!current.isAfter(_endDate!)) {
      final dateStr =
          "${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}";

      addedDates.add(dateStr);

      final dayOffRef = fs.collection('doctor_days_off').doc();

      batch.set(dayOffRef, {
        "doctorId": doctorId,
        "date": dateStr,
        "reason": reason,
        "createdAt": FieldValue.serverTimestamp(),
      });

      current = current.add(const Duration(days: 1));
    }

    // ✅ إلغاء جميع المواعيد ضمن الفترة
    final apptsSnap = await fs
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    for (final doc in apptsSnap.docs) {
      final data = doc.data();
      final dateTime = data["dateTime"];

      if (dateTime is Timestamp) {
        final date = dateTime.toDate();
        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        if (addedDates.contains(dateStr)) {
          final slotId = data["slotId"];
          batch.update(doc.reference, {"status": "canceled"});

          if (slotId != null && slotId is String) {
            batch.update(fs.collection('doctor_slots').doc(slotId), {
              "taken": false,
            });
          }
        }
      }
    }

    await batch.commit();

    _reasonController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم حفظ أيام الغياب وإلغاء المواعيد المتعارضة"),
      ),
    );
  }

  // ✅ حذف يوم غياب واحد
  Future<void> _deleteDayOff(DocumentSnapshot doc) async {
    final doctorId = _resolvedDoctorId;
    if (doctorId == null) return;

    final fs = FirebaseFirestore.instance;
    final batch = fs.batch();

    final dateStr = (doc['date'] ?? '').toString();

    // حذف يوم الغياب
    batch.delete(doc.reference);

    // إعادة فتح جميع slots لذلك اليوم
    final slotsSnap = await fs
        .collection('doctor_slots')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: dateStr)
        .get();

    for (final s in slotsSnap.docs) {
      batch.update(s.reference, {"taken": false});
    }

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم حذف يوم الغياب وإعادة فتح المواعيد")),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDoctor) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: widget.hideInnerHeader
            ? null
            : AppBar(title: const Text("أيام الغياب")),
        body: Center(child: Text(_error!)),
      );
    }

    final doctorId = _resolvedDoctorId!;

    return Scaffold(
      appBar: widget.hideInnerHeader
          ? null
          : AppBar(title: const Text("أيام الغياب")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                _startDate == null
                    ? "اختيار فترة الغياب"
                    : "من ${_startDate!.day}/${_startDate!.month} "
                          "إلى ${_endDate!.day}/${_endDate!.month}",
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: "سبب الغياب (اختياري)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDaysOff,
                child: const Text("حفظ"),
              ),
            ),

            const Divider(height: 32),

            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "أيام الغياب المسجلة:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // ✅ عرض الأيام المسجلة
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctor_days_off')
                    .where('doctorId', isEqualTo: doctorId)
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snap.hasError) {
                    return const Center(child: Text("خطأ في تحميل البيانات"));
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(child: Text("لا توجد أيام غياب مسجلة"));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      return Card(
                        child: ListTile(
                          title: Text(d['date'] ?? ''),
                          subtitle: Text(d['reason'] ?? ""),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'حذف يوم الغياب',
                            onPressed: () => _deleteDayOff(d),
                          ),
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
