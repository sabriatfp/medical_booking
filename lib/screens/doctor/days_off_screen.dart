// lib/screens/doctor/days_off_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveDoctorId();
    });
  }

  Future<void> _resolveDoctorId() async {
    try {
      if (widget.doctorId != null && widget.doctorId!.isNotEmpty) {
        _resolvedDoctorId = widget.doctorId;
      } else {
        _resolvedDoctorId = await _doctorService.getDoctorId();
      }

      if (_resolvedDoctorId == null) {
        if (!mounted) return;
        final t = AppLocalizations.of(context)!;
        setState(() {
          _error = t.doctorIdNotFound;
          _loadingDoctor = false;
        });
        return;
      }

      if (mounted) setState(() => _loadingDoctor = false);
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      setState(() {
        _error = t.errorFindingDoctor;
        _loadingDoctor = false;
      });
    }
  }

  // ✅ Pick date range
  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      locale: const Locale('fr'),
    );

    if (range == null) return;

    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
  }

  // ✅ Save days off + cancel conflicting appointments
  Future<void> _saveDaysOff() async {
    final t = AppLocalizations.of(context)!;

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

      final ref = fs.collection('doctor_days_off').doc();
      batch.set(ref, {
        "doctorId": doctorId,
        "date": dateStr,
        "reason": reason,
        "createdAt": FieldValue.serverTimestamp(),
      });

      current = current.add(const Duration(days: 1));
    }

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
          batch.update(doc.reference, {"status": "canceled"});

          final slotId = data["slotId"];
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.daysOffSaved)));
  }

  // ✅ Delete a day off
  Future<void> _deleteDayOff(DocumentSnapshot doc) async {
    final t = AppLocalizations.of(context)!;

    final doctorId = _resolvedDoctorId;
    if (doctorId == null) return;

    final fs = FirebaseFirestore.instance;
    final batch = fs.batch();

    final dateStr = (doc['date'] ?? '').toString();

    batch.delete(doc.reference);

    final slotsSnap = await fs
        .collection('doctor_slots')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: dateStr)
        .get();

    for (final s in slotsSnap.docs) {
      batch.delete(s.reference);
    }

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.dayOffDeleted)));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loadingDoctor) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: widget.hideInnerHeader ? null : AppBar(title: Text(t.daysOff)),
        body: Center(child: Text(_error!)),
      );
    }

    final doctorId = _resolvedDoctorId!;

    return Scaffold(
      appBar: widget.hideInnerHeader ? null : AppBar(title: Text(t.daysOff)),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ اختيار فترة الغياب
            GestureDetector(
              onTap: _pickDateRange,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _startDate == null
                              ? Icons.event_busy
                              : Icons.event_available,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.pickDaysOffRange,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _startDate == null
                                  ? t.tapToChoose
                                  : "${t.from} ${_startDate!.day}/${_startDate!.month} "
                                        "${t.to} ${_endDate!.day}/${_endDate!.month}",
                              style: TextStyle(
                                color: _startDate == null
                                    ? Colors.grey.shade600
                                    : Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: _startDate == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: t.reasonOptional,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_startDate == null || _endDate == null)
                    ? null
                    : _saveDaysOff,
                child: Text(t.save),
              ),
            ),

            const Divider(height: 32),

            Align(
              // alignment: Alignment.centerRight,
              child: Text(
                t.savedDaysOff,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // ✅ قائمة أيام الغياب
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
                    return Center(child: Text(t.errorLoadingData));
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(child: Text(t.noDaysOff));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      return Card(
                        child: ListTile(
                          title: Text(d['date'] ?? ''),
                          subtitle: Text(d['reason'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: t.deleteDayOff,
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
