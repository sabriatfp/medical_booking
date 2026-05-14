import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

import '../models/doctor.dart';
import '../widgets/doctor_card.dart';
import 'doctor_details_screen.dart';

class DoctorsFilterScreen extends StatefulWidget {
  const DoctorsFilterScreen({super.key});

  @override
  State<DoctorsFilterScreen> createState() => _DoctorsFilterScreenState();
}

class _DoctorsFilterScreenState extends State<DoctorsFilterScreen> {
  // Dropdown data
  List<QueryDocumentSnapshot> governorates = [];
  List<QueryDocumentSnapshot> specialties = [];

  String? selectedGovernorateId;
  String? selectedSpecialtyId;

  bool loadingFilters = true;
  bool searching = false;

  // ✅ ✅ الآن نستعمل Doctor model
  List<Doctor> doctors = [];

  @override
  void initState() {
    super.initState();
    loadFilters();
  }

  Future<void> loadFilters() async {
    final govSnap = await FirebaseFirestore.instance
        .collection('governorates')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get();

    final specSnap = await FirebaseFirestore.instance
        .collection('specialties')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .get();

    setState(() {
      governorates = govSnap.docs;
      specialties = specSnap.docs;
      loadingFilters = false;
    });
  }

  Future<void> searchDoctors() async {
    setState(() {
      searching = true;
      doctors = [];
    });

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'doctors',
    );

    // ✅ فلترة حسب الولاية (اختياري)
    if (selectedGovernorateId != null && selectedGovernorateId!.isNotEmpty) {
      query = query.where('governorateId', isEqualTo: selectedGovernorateId);
    }

    // ✅ فلترة حسب الاختصاص (اختياري)
    if (selectedSpecialtyId != null && selectedSpecialtyId!.isNotEmpty) {
      query = query.where('specialtyId', isEqualTo: selectedSpecialtyId);
    }

    final snap = await query.get();

    setState(() {
      doctors = snap.docs.map((d) => Doctor.fromMap(d.id, d.data())).toList();
      searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(title: Text(t.searchDoctors)),
      body: loadingFilters
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 Filters
                Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedGovernorateId,
                          decoration: InputDecoration(
                            labelText: t.governorate,
                            border: const OutlineInputBorder(),
                          ),
                          items: governorates.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                d['name_$lang'] ??
                                    d['name_fr'] ??
                                    d['name_ar'] ??
                                    '',
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => selectedGovernorateId = v),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: selectedSpecialtyId,
                          decoration: InputDecoration(
                            labelText: t.specialty,
                            border: const OutlineInputBorder(),
                          ),
                          items: specialties.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                d['name_$lang'] ??
                                    d['name_fr'] ??
                                    d['name_ar'] ??
                                    '',
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => selectedSpecialtyId = v),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: searching ? null : searchDoctors,
                            icon: const Icon(Icons.search),
                            label: Text(t.search),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 📋 Results
                Expanded(
                  child: searching
                      ? const Center(child: CircularProgressIndicator())
                      : doctors.isEmpty
                      ? Center(
                          child: Text(
                            t.noResultsFound,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: doctors.length,
                          itemBuilder: (context, index) {
                            final doctor = doctors[index];

                            return DoctorCard(
                              doctor: doctor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DoctorDetailsScreen(doctor: doctor),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
