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
          final now = DateTime.now().toUtc();

          // ✅ ✅ 🔥 تنظيف القائمة (بدون فراغات)
          final visibleDoctors = doctors.where((d) {
            // إخفاء الطبيب بعد انتهاء المهلة
            if (d.gracePeriodEnd != null && d.gracePeriodEnd!.isBefore(now)) {
              return false;
            }
            return true;
          }).toList();
          visibleDoctors.sort((a, b) {
            final aActive = a.subscriptionActive == true;
            final bActive = b.subscriptionActive == true;

            if (aActive == bActive) return 0;
            return aActive ? -1 : 1; // ✅ active يطلع فوق
          });
          if (visibleDoctors.isEmpty) {
            return Center(child: Text(t.noDoctorsAvailable));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visibleDoctors.length,
            itemBuilder: (context, i) {
              final d = visibleDoctors[i];

              // ✅ تحديد الحالة
              bool isExpired = false;

              if (d.subscriptionActive == false) {
                isExpired = true;
              }

              if (d.subscriptionEnd != null &&
                  d.subscriptionEnd!.isBefore(now)) {
                isExpired = true;
              }

              // ✅ حساب الأيام المتبقية
              int? remainingDays;

              if (d.gracePeriodEnd != null) {
                remainingDays = d.gracePeriodEnd!.difference(now).inDays;

                if (remainingDays < 0) remainingDays = 0;
              }

              return Opacity(
                opacity: isExpired ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: isExpired,
                  child: DoctorCard(
                    doctor: d,
                    isExpired: isExpired, // ✅ جديد
                    remainingDays: remainingDays, // ✅ جديد
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorDetailsScreen(doctor: d),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
