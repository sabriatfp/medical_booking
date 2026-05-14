import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import '../widgets/doctor_card.dart';
import 'doctor_details_screen.dart';
import '../models/doctor.dart';

class DoctorsListScreen extends StatelessWidget {
  const DoctorsListScreen({super.key});

  Future<List<Doctor>> _loadDoctors() async {
    final snap = await FirebaseFirestore.instance.collection('doctors').get();

    return snap.docs.map((d) {
      return Doctor.fromMap(d.id, d.data());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.doctorsList), centerTitle: true),

      body: FutureBuilder<List<Doctor>>(
        future: _loadDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(t.failedToLoadDoctors));
          }

          final doctors = snapshot.data ?? [];

          if (doctors.isEmpty) {
            return Center(child: Text(t.noDoctorsAvailable));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: doctors.length,
            itemBuilder: (context, i) {
              final d = doctors[i];

              return DoctorCard(
                doctor: d,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorDetailsScreen(doctor: d),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
