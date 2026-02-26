import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';

import 'slots_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
 
  Map<String, dynamic>? scheduleData;
  bool loading = true;
  Set<String> daysOff = {};
 

  @override
  void initState() {
    super.initState();
    loadSchedule();
  }

  Future<void> loadSchedule() async {
  final doctorId = widget.doctor.id; // ✅ هذا هو المهم

  // جلب بيانات جدول الطبيب
  final doctorSnap = await FirebaseFirestore.instance
      .collection('doctors')
      .doc(doctorId)
      .get();

  if (doctorSnap.exists) {
    scheduleData = doctorSnap.data();
  }

  // جلب أيام الغياب
  final offSnap = await FirebaseFirestore.instance
      .collection('doctor_days_off')
      .where('doctorId', isEqualTo: doctorId)
      .get();

  daysOff = offSnap.docs.map((d) => (d['date'] as String).trim()).toSet();

  setState(() => loading = false);
}


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    

    return Scaffold(
      appBar: AppBar(title: Text(widget.doctor.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          const Text(
            "إختر اليوم",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (scheduleData?['weeks'] != null && scheduleData!['weeks'].isNotEmpty)
            _buildDaysList(scheduleData!['weeks'])
          else
            const Text("لا توجد مواعيد متاحة."),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final d = widget.doctor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundImage: (d.photoUrl != null && d.photoUrl!.isNotEmpty)
                ? NetworkImage(d.photoUrl!)
                : null,
            child: (d.photoUrl == null || d.photoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 48)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(d.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.medical_services, size: 18),
            const SizedBox(width: 6),
            Text(d.specialty, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber.shade700, size: 18),
            const SizedBox(width: 4),
            Text(d.rating.toStringAsFixed(1)),
            const SizedBox(width: 16),
            const Icon(Icons.attach_money, size: 18),
            Text('${d.price}'),
            const SizedBox(width: 16),
            Icon(
              d.isAvailable ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: d.isAvailable ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(d.isAvailable ? 'متاح' : 'غير متاح'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.place, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(d.address)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.phone, size: 18),
            const SizedBox(width: 6),
            Text(d.phone),
          ],
        ),
      ],
    );
  }

  Widget _buildDaysList(List weeks) {
    List allDays = [];
    for (var w in weeks) {
      allDays.addAll(w["days"]);
    }

    return Column(
      children: allDays.map<Widget>((day) {
        final date = (day["date"] as String).trim();
        final available = day["available"] == true;
        final full = day["full"] == true;
        final isDayOff = daysOff.contains(date);

        Color cardColor;
        String subtitle;

        if (isDayOff) {
          cardColor = Colors.orange.shade100;
          subtitle = "الطبيب في إجازة";
        } else if (!available) {
          cardColor = Colors.grey.shade200;
          subtitle = "غير متاح";
        } else if (full) {
          cardColor = Colors.red.shade100;
          subtitle = "ممتلئ";
        } else {
          cardColor = Colors.white;
          subtitle = "متاح";
        }

        return Card(
          color: cardColor,
          child: ListTile(
            title: Text(date),
            subtitle: Text(subtitle),
            enabled: available && !full && !isDayOff,
            onTap: available && !full && !isDayOff
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SlotsScreen(
                          doctor: widget.doctor,
                          date: date,
                          schedule: scheduleData!,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        );
      }).toList(),
    );
  }
}
