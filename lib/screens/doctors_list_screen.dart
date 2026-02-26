import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';
import 'doctor_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorsListScreen extends StatelessWidget {
  const DoctorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("قائمة الأطباء")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .where('isAvailable', isEqualTo: true) // 🔥 لا يظهر المنتهي اشتراكه
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ أثناء جلب الأطباء"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("لا يوجد أطباء متاحين حالياً"));
          }

          final doctors = docs
              .map(
                (d) => Doctor.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList();

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundImage: doc.photoUrl != null
                              ? NetworkImage(doc.photoUrl!)
                              : null,
                          child: doc.photoUrl == null
                              ? const Icon(Icons.person, size: 28)
                              : null,
                        ),
                        title: Text(
                          doc.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text("الاختصاص: ${doc.specialty}"),

                        /// 🔥 السعر الذكي
                        trailing: doc.isPriceVisible
                            ? Text(
                                "${doc.price} د.ت",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Text(
                                "السعر عند الحضور",
                                style: TextStyle(
                                  color: Color.fromARGB(117, 158, 158, 158),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 6),

                      /// العنوان
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Expanded(child: Text(doc.address)),
                          IconButton(
                            icon: const Icon(Icons.map, color: Colors.blue),
                            onPressed: () {
                              final url =
                                  "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(doc.address)}";
                              launchUrl(Uri.parse(url));
                            },
                          ),
                        ],
                      ),

                      /// الهاتف
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.teal),
                          const SizedBox(width: 4),
                          Expanded(child: Text(doc.phone)),
                          IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () {
                              launchUrl(Uri.parse("tel:${doc.phone}"));
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// زر الحجز
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: const Text("حجز موعد"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DoctorDetailsScreen(doctor: doc),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
