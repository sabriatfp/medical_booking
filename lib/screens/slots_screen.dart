import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

class SlotsScreen extends StatefulWidget {
  final dynamic doctor;
  final String date;
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
  Set<String> _daysOff = {};

  @override
  void initState() {
    super.initState();
    _loadDaysOff();
  }

  Future<void> _loadDaysOff() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('doctor_days_off')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .get();

      _daysOff = snap.docs.map((d) => (d['date'] as String).trim()).toSet();
    } catch (e) {
      _daysOff = {};
    }

    if (mounted) setState(() {});
  }

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

  List<String> _generateTimes() {
    final day = _findDayData();
    if (day == null) return [];

    final slots = day['slots'];
    if (slots != null && slots is List) {
      return List<String>.from(slots);
    }
    return [];
  }

  Future<void> _bookSlot(String time) async {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.mustLogin)));
      return;
    }

    final selectedDay = _findDayData();
    if (selectedDay == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.cannotBookThisDay)));
      return;
    }

    if (_daysOff.contains(widget.date)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.doctorDayOff)));
      return;
    }

    if (selectedDay["available"] != true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.dayNotAvailable)));
      return;
    }

    if (selectedDay["full"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.dayIsFull)));
      return;
    }

    final allowedTimes = List<String>.from(selectedDay["slots"] ?? []);
    if (!allowedTimes.contains(time)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.timeNotAvailable)));
      return;
    }

    final selectedDateTime = DateTime.parse("${widget.date} $time");
    if (selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.cannotBookPastTime)));
      return;
    }

    setState(() => _loading = true);

    final fs = FirebaseFirestore.instance;
    final slotId = "${widget.doctor.id}_${widget.date}_$time";
    final slotRef = fs.collection('doctor_slots').doc(slotId);
    final existingSlot = await slotRef.get();
    if (existingSlot.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.slotAlreadyTaken)));
      setState(() => _loading = false);
      return;
    }
    final appointmentRef = fs.collection('appointments').doc();

    final docSnap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctor.id)
        .get();

    final doctorData = docSnap.data() ?? {};
    final doctorName = doctorData['name'] ?? '';
    final doctorSpecialty = doctorData['specialtyLabel'] ?? '';
    final doctorUid = doctorData['ownerUid'];

    if (doctorUid == null) {
      throw Exception("doctor_uid_missing");
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final patientDoc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(user.uid)
        .get();

    final patientName = (userDoc.data()?['name'] ?? '').toString();

    final patientPhone = (patientDoc.data()?['phone'] ?? '').toString();

    try {
      await fs.runTransaction((t1) async {
        final slotSnap = await t1.get(slotRef);

        if (slotSnap.exists) {
          final data = slotSnap.data();
          if (data != null && data['taken'] == true) {
            throw Exception("taken");
          }
        }

        if (!allowedTimes.contains(time)) {
          throw Exception("invalid_slot");
        }

        t1.set(slotRef, {
          "doctorId": widget.doctor.id,
          "doctorUid": doctorUid,

          "date": widget.date,
          "time": time,
          "taken": true,
          "patientId": user.uid,
        });

        t1.set(appointmentRef, {
          "doctorId": widget.doctor.id,
          "doctorUid": doctorUid,
          "patientId": user.uid,
          "doctorName": doctorName,
          "doctorSpecialty": doctorSpecialty,
          "patientName": patientName,
          "patientPhone": patientPhone,
          "dateTime": Timestamp.fromDate(selectedDateTime),
          "slotId": slotId,
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.bookingSent)));
    } catch (e) {
      String message = t.unexpectedError;

      if (e.toString().contains("taken")) {
        message = t.slotAlreadyTaken;
      } else if (e.toString().contains("invalid_slot")) {
        message = t.invalidSlot;
      } else if (e.toString().contains("doctor_uid_missing")) {
        message = t.unexpectedError; // أو نص مخصص لاحقًا
      }

      // ✅ مفيد جدًا للتشخيص
      debugPrint("Booking error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final times = _generateTimes();

    return Scaffold(
      appBar: AppBar(title: Text(t.chooseAppointment)),
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
