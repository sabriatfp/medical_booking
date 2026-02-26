// lib/screens/doctor/doctor_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  String? doctorId;

  /// المدة المعتمدة فعليًا (المحفوظة في Firestore) — تظهر عليها ✔
  int? slotDuration;

  /// الاختيار المؤقّت في الواجهة قبل التفعيل — يتلوّن Tonal خفيف
  int? selectedSlot;

  final List<String> weekDays = const [
    "الإثنين",
    "الثلاثاء",
    "الأربعاء",
    "الخميس",
    "الجمعة",
    "السبت",
    "الأحد",
  ];

  /// النموذج الأسبوعي الأساسي (يمكن للطبيب تعديله)
  Map<String, Map<String, dynamic>> weeklyTemplate = {
    "الإثنين": {"available": true, "start": "08:00", "end": "16:00"},
    "الثلاثاء": {"available": true, "start": "08:00", "end": "16:00"},
    "الأربعاء": {"available": true, "start": "08:00", "end": "16:00"},
    "الخميس": {"available": true, "start": "08:00", "end": "16:00"},
    "الجمعة": {"available": true, "start": "08:00", "end": "16:00"},
    "السبت": {"available": false, "start": "08:00", "end": "16:00"},
    "الأحد": {"available": false, "start": "08:00", "end": "16:00"},
  };

  /// الأسابيع الثلاثة القادمة (21 يوم)
  List<Map<String, dynamic>> weeks = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!snap.exists) return;

    doctorId = snap.data()?['doctorId'];
    if (doctorId == null) return;

    await _loadDoctorSchedule();
    _generateThreeWeeks();
    await _updateFullDays();

    if (mounted) setState(() {});
  }

  /// تحميل إعدادات الطبيب (slotDuration + weeklyTemplate + weeks إن وجدت)
  Future<void> _loadDoctorSchedule() async {
    if (doctorId == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();
    if (!snap.exists) return;

    final data = snap.data()!;
    if (data['slotDuration'] != null) {
      slotDuration = data['slotDuration'];
      selectedSlot = slotDuration; // ✅ حتى تظهر الشيب المفعّلة عند الدخول
    }

    if (data['weeklyTemplate'] != null) {
      final t = Map<String, dynamic>.from(data['weeklyTemplate']);
      t.forEach((key, value) {
        if (weeklyTemplate[key] != null) {
          weeklyTemplate[key]!['available'] = value['available'];
          weeklyTemplate[key]!['start'] = value['start'];
          weeklyTemplate[key]!['end'] = value['end'];
        }
      });
    }

    if (data['weeks'] != null) {
      weeks = List<Map<String, dynamic>>.from(data['weeks']);
    }
  }

  DateTime _nextMonday(DateTime from) {
    int diff = (DateTime.monday - from.weekday) % 7;
    if (diff == 0) diff = 7;
    return from.add(Duration(days: diff));
  }

  List<Map<String, dynamic>> _generateWeekDays(DateTime startDate) {
    final List<Map<String, dynamic>> output = [];
    for (int i = 0; i < 7; i++) {
      final d = startDate.add(Duration(days: i));
      final dateStr = DateFormat("yyyy-MM-dd").format(d);
      final dayName = weekDays[d.weekday - 1];
      final tmpl = weeklyTemplate[dayName]!;
      output.add({
        "date": dateStr,
        "available": tmpl["available"],
        "start": tmpl["start"],
        "end": tmpl["end"],
        "full": false,
      });
    }
    return output;
  }

  void _generateThreeWeeks() {
    final today = DateTime.now();
    final w1Start = _nextMonday(today);

    weeks = [];
    weeks.add({
      "startDate": w1Start.toIso8601String(),
      "days": _generateWeekDays(w1Start),
    });

    final w2Start = w1Start.add(const Duration(days: 7));
    weeks.add({
      "startDate": w2Start.toIso8601String(),
      "days": _generateWeekDays(w2Start),
    });

    final w3Start = w1Start.add(const Duration(days: 14));
    weeks.add({
      "startDate": w3Start.toIso8601String(),
      "days": _generateWeekDays(w3Start),
    });

    if (mounted) setState(() {});
  }

  Future<int> _getAppointmentsCount(DateTime day) async {
    if (doctorId == null) return 0;
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

    final query = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: start)
        .where('dateTime', isLessThanOrEqualTo: end)
        .get();

    int c = 0;
    for (var doc in query.docs) {
      final d = doc.data();
      if (d['status'] == 'pending' || d['status'] == 'confirmed') c++;
    }
    return c;
  }

  int _calcMaxSlots(String start, String end, int slotMinutes) {
    final s = start.split(":");
    final e = end.split(":");
    final sm = int.parse(s[0]) * 60 + int.parse(s[1]);
    final em = int.parse(e[0]) * 60 + int.parse(e[1]);
    final total = em - sm;
    if (total <= 0) return 0;
    return (total / slotMinutes).floor();
  }

  /// تحديث حالة الأيام الممتلئة اعتمادًا على slotDuration وعدد المواعيد
  Future<void> _updateFullDays() async {
    if (slotDuration == null) return;

    for (var w in weeks) {
      for (var day in w["days"]) {
        if (day["available"] != true) {
          day["full"] = false;
          continue;
        }
        final date = DateTime.parse(day["date"]);
        final max = _calcMaxSlots(day["start"], day["end"], slotDuration!);
        final count = await _getAppointmentsCount(date);
        day["full"] = count >= max;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("إعدادات التوقيت")),
      body: doctorId == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---------------------------
                // مدة الفحص الطبي (Slot Duration)
                // ---------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "مدة الفحص الطبي (Slot Duration)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // تنبيه لطيف في حال لا توجد قيمة مفعّلة
                        if (slotDuration == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer.withOpacity(.20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "لم يتم تحديد مدة الفحص بعد",
                              style: TextStyle(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // الشيبس (اختيار مؤقّت Tonal + مفعّل ✔)
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [10, 15, 20, 25, 30].map((v) {
                            final bool isActive = slotDuration == v; // ✔
                            final bool isTentative =
                                selectedSlot == v && !isActive; // Tonal

                            final Color bgColor = isActive
                                ? scheme.primary.withOpacity(.16)
                                : (isTentative
                                      ? scheme.secondaryContainer.withOpacity(
                                          .35,
                                        )
                                      : scheme.surfaceContainerHighest
                                            .withOpacity(.30));

                            final Color fgColor = isActive
                                ? scheme.primary
                                : (isTentative
                                      ? scheme.onSecondaryContainer
                                      : scheme.onSurfaceVariant);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: ChoiceChip(
                                selected: isActive,
                                showCheckmark: false,
                                onSelected: (picked) {
                                  if (!picked) return;
                                  if (!mounted) return;
                                  setState(() {
                                    selectedSlot = v; // اختيار مؤقّت فقط
                                  });
                                },
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isActive) ...[
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                    ] else if (isTentative) ...[
                                      Icon(
                                        Icons.schedule,
                                        size: 18,
                                        color: scheme.onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      "$v دقيقة",
                                      style: TextStyle(
                                        color: fgColor,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.transparent,
                                selectedColor: Colors.transparent,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),

                        // زر تفعيل — يحفظ المؤقّت ويجعله هو المعتمد ✔
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text("تفعيل"),
                            onPressed:
                                (selectedSlot == null || doctorId == null)
                                ? null
                                : () async {
                                    final v = selectedSlot!;
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('doctors')
                                          .doc(doctorId)
                                          .set({
                                            'slotDuration': v,
                                          }, SetOptions(merge: true));

                                      if (!mounted) return;
                                      setState(() {
                                        slotDuration =
                                            v; // انتقال ✔ للقيمة الجديدة
                                      });

                                      await _updateFullDays();

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "تم تفعيل مدة الفحص: $v دقيقة",
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("تعذّر التفعيل: $e"),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------
                // النموذج الأسبوعي الأساسي
                // ---------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "النموذج الأسبوعي الأساسي",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: weekDays.map((day) {
                            final d = weeklyTemplate[day]!;
                            final available = d["available"] == true;
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        day,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Switch(
                                      value: available,
                                      onChanged: (v) {
                                        if (!mounted) return;
                                        setState(
                                          () =>
                                              weeklyTemplate[day]!["available"] =
                                                  v,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                if (available)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              final t = await pickTime(
                                                context,
                                                d["start"],
                                              );
                                              if (t != null && mounted) {
                                                setState(() => d["start"] = t);
                                              }
                                            },
                                            child: _timeBox(
                                              icon: Icons.access_time,
                                              label: "بداية",
                                              value: d["start"],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              final t = await pickTime(
                                                context,
                                                d["end"],
                                              );
                                              if (t != null && mounted) {
                                                setState(() => d["end"] = t);
                                              }
                                            },
                                            child: _timeBox(
                                              icon: Icons.access_time,
                                              label: "نهاية",
                                              value: d["end"],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const Divider(),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------
                // تخصيص الأسابيع القادمة (21 يومًا)
                // ---------------------------
                const Text(
                  "تخصيص الأسابيع القادمة (21 يومًا)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Column(
                  children: List.generate(weeks.length, (i) {
                    final w = weeks[i];
                    final startDate = DateTime.parse(
                      w["startDate"].toString().trim(),
                    );
                    final days = w["days"] as List;
                    final title =
                        "الأسبوع ${i + 1} (${startDate.day}/${startDate.month})";
                    return Card(
                      child: ExpansionTile(
                        title: Text(title),
                        children: days.map<Widget>((d) {
                          return ListTile(
                            leading: d["full"] == true
                                ? _redDot()
                                : const SizedBox(),
                            title: Text(d["date"]),
                            subtitle: Text("من ${d["start"]} إلى ${d["end"]}"),
                            trailing: Switch(
                              value: d["available"] == true,
                              onChanged: (v) {
                                if (!mounted) return;
                                setState(() => d["available"] = v);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                // ---------------------------
                // حفظ الإعدادات
                // ---------------------------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _saveDoctorSchedule();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم حفظ الإعدادات بنجاح")),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("حفظ الإعدادات"),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _timeBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text("$label: $value"),
        ],
      ),
    );
  }

  Widget _redDot() {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
      ),
    );
  }

  Future<void> _saveDoctorSchedule() async {
    if (doctorId == null) return;
    await FirebaseFirestore.instance.collection('doctors').doc(doctorId).set({
      "slotDuration": slotDuration, // ✅ نحفظ المفعّلة (ليست المؤقّتة)
      "weeklyTemplate": weeklyTemplate,
      "weeks": weeks,
      "ownerUid": FirebaseAuth.instance.currentUser!.uid,
    }, SetOptions(merge: true));
  }
}

/// اختيار وقت بسيط يعيد "HH:mm"
Future<String?> pickTime(BuildContext context, String initial) async {
  final p = initial.split(":");
  final t = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  final res = await showTimePicker(context: context, initialTime: t);
  if (res == null) return null;
  final h = res.hour.toString().padLeft(2, '0');
  final m = res.minute.toString().padLeft(2, '0');
  return "$h:$m";
}
