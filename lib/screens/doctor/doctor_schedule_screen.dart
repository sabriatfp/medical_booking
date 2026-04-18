// lib/screens/doctor/doctor_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import '../../services/doctor_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  final String? doctorId;
  final bool asSecretary;
  final bool hideInnerHeader;

  const DoctorScheduleScreen({
    super.key,
    this.doctorId,
    this.asSecretary = false,
    this.hideInnerHeader = false,
  });

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  String? _resolvedDoctorId;

  bool _loading = true;
  String? _error;

  int? slotDuration;
  int? selectedSlot;

  final List<String> weekDays = [
    "الإثنين",
    "الثلاثاء",
    "الأربعاء",
    "الخميس",
    "الجمعة",
    "السبت",
    "الأحد",
  ];

  Map<String, Map<String, dynamic>> weeklyTemplate = {
    "الإثنين": {"available": true, "start": "08:00", "end": "16:00"},
    "الثلاثاء": {"available": true, "start": "08:00", "end": "16:00"},
    "الأربعاء": {"available": true, "start": "08:00", "end": "16:00"},
    "الخميس": {"available": true, "start": "08:00", "end": "16:00"},
    "الجمعة": {"available": true, "start": "08:00", "end": "16:00"},
    "السبت": {"available": false, "start": "08:00", "end": "16:00"},
    "الأحد": {"available": false, "start": "08:00", "end": "16:00"},
  };

  Set<String> exceptionalDaysOff = {};
  List<Map<String, dynamic>> weeks = [];

  @override
  void initState() {
    super.initState();
    _resolveDoctorId();
  }

  // -------------------------------
  // توليد الفترات الزمنية
  // -------------------------------
  List<String> generateSlots(String start, String end, int duration) {
    final s = start.split(":");
    final e = end.split(":");

    int startMin = int.parse(s[0]) * 60 + int.parse(s[1]);
    int endMin = int.parse(e[0]) * 60 + int.parse(e[1]);

    List<String> out = [];

    while (startMin + duration <= endMin) {
      final h = (startMin ~/ 60).toString().padLeft(2, '0');
      final m = (startMin % 60).toString().padLeft(2, '0');
      out.add("$h:$m");
      startMin += duration;
    }

    return out;
  }

  // -------------------------------
  // تحميل doctorId + جدول العمل
  // -------------------------------
  Future<void> _resolveDoctorId() async {
    try {
      // 1️⃣ تحديد doctorId
      if (widget.doctorId != null && widget.doctorId!.isNotEmpty) {
        _resolvedDoctorId = widget.doctorId;
      } else {
        _resolvedDoctorId = await DoctorService().getDoctorId();
      }

      if (_resolvedDoctorId == null) {
        _error = AppLocalizations.of(context)!.errorFindingDoctorId;
        return;
      }

      // 2️⃣ تحميل بيانات الطبيب الأساسية
      await _loadDoctorSchedule();

      // 3️⃣ تحميل أيام العطل
      await _loadExceptionalDaysOff();

      // ✅ 4️⃣ تطبيق Rolling هنا (المكان الصحيح)
      if (slotDuration != null && slotDuration! > 0) {
        await DoctorService.normalizeRollingWeeks(
          doctorId: _resolvedDoctorId!,
          weeklyTemplate: weeklyTemplate,
          exceptionalDaysOff: exceptionalDaysOff,
          slotDuration: slotDuration!,
        );

        // ✅ 5️⃣ إعادة تحميل الجدول بعد التطبيع
        await _loadDoctorSchedule();
      }

      // 6️⃣ تحديث الأيام الممتلئة
      await _updateFullDays();
    } catch (e) {
      _error = AppLocalizations.of(context)!.unexpectedError;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // تحميل أيام العطل الاستثنائية
  Future<void> _loadExceptionalDaysOff() async {
    if (_resolvedDoctorId == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("doctor_days_off")
        .where("doctorId", isEqualTo: _resolvedDoctorId)
        .get();

    exceptionalDaysOff = snap.docs
        .map((d) => (d["date"] as String).trim())
        .toSet();
  }

  // تحميل slotDuration + weeklyTemplate + weeks
  Future<void> _loadDoctorSchedule() async {
    final doctorId = _resolvedDoctorId;
    if (doctorId == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("doctors")
        .doc(doctorId)
        .get();

    if (!snap.exists) return;
    final data = snap.data()!;

    if (data["slotDuration"] != null) {
      final sd = data["slotDuration"];
      slotDuration = sd is int ? sd : (sd as double).toInt();
      selectedSlot = slotDuration;
    }

    if (data["weeklyTemplate"] != null) {
      final t = Map<String, dynamic>.from(data["weeklyTemplate"]);
      t.forEach((key, value) {
        if (weeklyTemplate[key] != null && value is Map) {
          weeklyTemplate[key]!["available"] = value["available"];
          weeklyTemplate[key]!["start"] = value["start"];
          weeklyTemplate[key]!["end"] = value["end"];
        }
      });
    }

    if (data["weeks"] != null) {
      weeks = List<Map<String, dynamic>>.from(data["weeks"]);
    }
  }

  // دوال الأسبوع — نفس المنطق
  DateTime _nextMonday(DateTime from) {
    int diff = (DateTime.monday - from.weekday) % 7;
    if (diff == 0) diff = 7;
    return from.add(Duration(days: diff));
  }

  Future<int> _getAppointmentsCount(DateTime day) async {
    final doctorId = _resolvedDoctorId;
    if (doctorId == null) return 0;

    try {
      final start = DateTime(day.year, day.month, day.day, 0, 0, 0);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final query = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('dateTime', isGreaterThanOrEqualTo: start)
          .where('dateTime', isLessThanOrEqualTo: end)
          .get();

      int count = 0;
      for (var doc in query.docs) {
        final status = doc.data()['status'];
        if (status == 'pending' || status == 'confirmed') count++;
      }
      return count;
    } catch (e) {
      debugPrint("❌ getAppointmentsCount ERROR: $e");
      return 0; // 👈 مهم جدًا حتى لا ينهار التطبيق
    }
  }

  // -------------------------------
  // توليد أسبوع كامل مع slots
  // -------------------------------
  List<Map<String, dynamic>> _generateWeekDays(DateTime startDate) {
    final List<Map<String, dynamic>> output = [];

    for (int i = 0; i < 7; i++) {
      final d = startDate.add(Duration(days: i));
      final dateStr = DateFormat("yyyy-MM-dd").format(d);
      final dayName = weekDays[d.weekday - 1];
      final tmpl = weeklyTemplate[dayName];

      if (tmpl == null) {
        output.add({
          "date": dateStr,
          "available": false,
          "start": null,
          "end": null,
          "slots": [],
          "full": true,
        });
        continue;
      }
      bool isDayOff = exceptionalDaysOff.contains(dateStr);
      bool available = tmpl["available"] == true && !isDayOff;

      List<String> slots = [];
      if (available && slotDuration != null) {
        slots = generateSlots(tmpl["start"], tmpl["end"], slotDuration!);
      }

      output.add({
        "date": dateStr,
        "available": available,
        "start": tmpl["start"],
        "end": tmpl["end"],
        "slots": slots,
        "full": false,
      });
    }

    return output;
  }

  // -------------------------------
  // تحديث حالة الأيام الممتلئة
  // -------------------------------
  Future<void> _updateFullDays() async {
    if (weeks.isEmpty) return;
    if (slotDuration == null) return;

    for (var w in weeks) {
      for (var day in w["days"]) {
        if (day["available"] != true) {
          day["full"] = false;
          continue;
        }

        final date = DateTime.parse(day["date"]);
        final maxSlots = (day["slots"] as List?)?.length ?? 0;
        final count = await _getAppointmentsCount(date);

        if (maxSlots == 0) {
          day["full"] = false;
        } else {
          day["full"] = count >= maxSlots;
        }
      }
    }

    if (mounted) setState(() {});
  }

  // ------------------------------------------------
  //                 UI يبدأ هنا
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: widget.hideInnerHeader
            ? null
            : AppBar(title: Text(t.scheduleSettings)),
        body: Center(child: Text(_error!)),
      );
    }

    final doctorId = _resolvedDoctorId!;

    return Scaffold(
      appBar: widget.hideInnerHeader
          ? null
          : AppBar(title: Text(t.scheduleSettings)),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --------------------------------------------
          //        مدة الفحص الطبي (Slot Duration)
          // --------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.slotDurationTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

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
                        t.slotDurationNotSet,
                        style: TextStyle(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [10, 15, 20, 25, 30].map((v) {
                      final bool isActive = slotDuration == v;
                      final bool isTentative = selectedSlot == v && !isActive;

                      final Color bgColor = isActive
                          ? scheme.primary.withOpacity(.16)
                          : (isTentative
                                ? scheme.secondaryContainer.withOpacity(.35)
                                : scheme.surfaceContainerHighest.withOpacity(
                                    .30,
                                  ));

                      final Color fgColor = isActive
                          ? scheme.primary
                          : (isTentative
                                ? scheme.onSecondaryContainer
                                : scheme.onSurfaceVariant);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: ChoiceChip(
                          selected: isActive,
                          showCheckmark: false,
                          onSelected: (picked) {
                            if (!picked) return;
                            setState(() => selectedSlot = v);
                          },
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isActive)
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                              if (isTentative)
                                Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: scheme.onSecondaryContainer,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                t.minutesLabel(v),
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

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: Text(t.enable),
                      onPressed: (selectedSlot == null)
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

                                setState(() => slotDuration = v);

                                // ✅ شغّل rolling فورًا
                                await DoctorService.normalizeRollingWeeks(
                                  doctorId: doctorId,
                                  weeklyTemplate: weeklyTemplate,
                                  exceptionalDaysOff: exceptionalDaysOff,
                                  slotDuration: v,
                                );

                                // ✅ أعد التحميل
                                await _loadDoctorSchedule();

                                // ✅ ثم احسب full days
                                await _updateFullDays();

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.slotEnabled(v))),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("${t.enableFailed}: $e"),
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

          // --------------------------------------------
          //       النموذج الأسبوعي الأساسي
          // --------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.weeklyTemplateTitle,
                    style: const TextStyle(
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
                                  setState(() => d["available"] = v);
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
                                        final tPicked = await pickTime(
                                          context,
                                          d["start"],
                                        );
                                        if (tPicked != null) {
                                          setState(() => d["start"] = tPicked);
                                        }
                                      },
                                      child: _timeBox(
                                        icon: Icons.access_time,
                                        label: t.startLabel,
                                        value: d["start"],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final tPicked = await pickTime(
                                          context,
                                          d["end"],
                                        );
                                        if (tPicked != null) {
                                          setState(() => d["end"] = tPicked);
                                        }
                                      },
                                      child: _timeBox(
                                        icon: Icons.access_time,
                                        label: t.endLabel,
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

          // --------------------------------------------
          // تخصيص الأسابيع القادمة (21 يومًا)
          // --------------------------------------------
          Text(
            t.customizeUpcomingWeeks,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  "${t.weekLabel(i + 1)} (${startDate.day}/${startDate.month})";

              return Card(
                child: ExpansionTile(
                  title: Text(title),
                  children: days.map<Widget>((d) {
                    return ListTile(
                      leading: d["full"] == true ? _redDot() : const SizedBox(),
                      title: Text(d["date"]),
                      subtitle: Text(
                        "${t.from} ${d["start"]} ${t.to} ${d["end"]}",
                      ),
                      trailing: Switch(
                        value: d["available"] == true,
                        onChanged: (v) {
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

          // --------------------------------------------
          // حفظ الإعدادات (Save)
          // --------------------------------------------
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(t.saveSettings),
              onPressed: () async {
                await _saveDoctorSchedule();
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.settingsSaved)));
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // UI Helper Widgets
  // -------------------------------
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

  // ---------------------------------------------
  // حفظ weeks + weeklyTemplate + slotDuration
  // ---------------------------------------------
  Future<void> _saveDoctorSchedule() async {
    final t = AppLocalizations.of(context)!;
    final doctorId = _resolvedDoctorId;
    if (doctorId == null) return;

    // 1️⃣ حفظ الإعدادات التي عدّلها الطبيب
    await FirebaseFirestore.instance.collection('doctors').doc(doctorId).set({
      "slotDuration": slotDuration,
      "weeklyTemplate": weeklyTemplate,
      "weeks": weeks,
      "ownerUid": FirebaseAuth.instance.currentUser!.uid,
    }, SetOptions(merge: true));

    // 2️⃣ تطبيق Rolling بعد الحفظ ✅
    if (slotDuration != null) {
      await DoctorService.normalizeRollingWeeks(
        doctorId: doctorId,
        weeklyTemplate: weeklyTemplate,
        exceptionalDaysOff: exceptionalDaysOff,
        slotDuration: slotDuration!,
      );
    }

    // 3️⃣ إعادة تحميل الجدول بعد rolling
    await _loadDoctorSchedule();

    // 4️⃣ تحديث حالة الأيام الممتلئة
    await _updateFullDays();
  }
}

/// اختيار وقت HH:mm مترجم
Future<String?> pickTime(BuildContext context, String initial) async {
  final t = AppLocalizations.of(context)!;

  final parts = initial.split(":");
  final initialTime = TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );

  final res = await showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: t.selectTime, // ✅ النص المستخدم في نافذة اختيار الوقت
  );

  if (res == null) return null;

  final h = res.hour.toString().padLeft(2, '0');
  final m = res.minute.toString().padLeft(2, '0');

  return "$h:$m";
}
