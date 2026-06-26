import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.data,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final notesController = TextEditingController();
  String? selectedVisitType;

  @override
  void initState() {
    super.initState();

    // ✅ تحميل البيانات
    notesController.text = (widget.data['doctorNotes'] ?? '').toString();

    selectedVisitType = widget.data['visitType'];
  }

  Future<void> save() async {
    final t = AppLocalizations.of(context)!;

    if (notesController.text.trim().isEmpty && selectedVisitType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.enterData)));
      return;
    }

    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notesController.text.trim().isNotEmpty) {
        updateData['doctorNotes'] = notesController.text.trim();
      }

      if (selectedVisitType != null) {
        updateData['visitType'] = selectedVisitType;
      }

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update(updateData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.savedSuccessfully)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.operationFailed)));
    }
  }

  Future<void> _callNumber(String phone) async {
    final t = AppLocalizations.of(context)!;

    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.phoneUnavailable)));
      return;
    }

    final uri = Uri.parse('tel:$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.callFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    DateTime? dt;
    if (widget.data['dateTime'] is Timestamp) {
      dt = (widget.data['dateTime'] as Timestamp).toDate();
    }

    final timeLabel = dt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(dt)
        : t.notAvailable;

    final patientName = (widget.data['patientName'] ?? t.patient).toString();

    final patientPhone = (widget.data['patientPhone'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: Text(t.appointmentDetails)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("${t.patient}: $patientName"),

          const SizedBox(height: 6),
          Text("${t.time}: $timeLabel"),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            icon: const Icon(Icons.phone),
            label: Text(t.callPatient),
            onPressed: () => _callNumber(patientPhone),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: notesController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: t.doctorNotes,
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: selectedVisitType,
            decoration: InputDecoration(
              labelText: t.visitType,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'consultation',
                child: Text(t.consultation),
              ),
              DropdownMenuItem(value: 'review', child: Text(t.review)),
              DropdownMenuItem(value: 'checkup', child: Text(t.checkup)),
            ],
            onChanged: (v) {
              setState(() {
                selectedVisitType = v;
              });
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton(onPressed: save, child: Text(t.save)),
        ],
      ),
    );
  }
}
