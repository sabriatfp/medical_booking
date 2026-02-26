import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoctorCalendarScreen extends StatefulWidget {
  const DoctorCalendarScreen({super.key});

  @override
  State<DoctorCalendarScreen> createState() => _DoctorCalendarScreenState();
}

class _DoctorCalendarScreenState extends State<DoctorCalendarScreen> {
  DateTime selectedMonth = DateTime.now();
  String? doctorId;

  Map<String, Map<String, dynamic>> calendarData = {};
  bool loading = true;

  // ✅ إحصائيات الشهر
  int totalAppointments = 0;
  int confirmedAppointments = 0;
  int cancelledAppointments = 0;
  double totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    fetchDoctorId();
  }

  Future<void> fetchDoctorId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    doctorId = doc.data()?['doctorId'];
    if (doctorId == null) {
      setState(() => loading = false);
      return;
    }

    await fetchCalendarData();
  }

  Future<void> fetchCalendarData() async {
    if (doctorId == null) return;

    setState(() => loading = true);

    calendarData.clear();
    totalAppointments = 0;
    confirmedAppointments = 0;
    cancelledAppointments = 0;
    totalRevenue = 0;

    /// 🔹 المواعيد
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    for (var doc in snap.docs) {
      final d = doc.data();
      final date = DateTime.tryParse(d['date'] ?? '');
      if (date == null) continue;

      if (date.year == selectedMonth.year &&
          date.month == selectedMonth.month) {
        totalAppointments++;

        final status = d['status'] ?? 'confirmed';
        final price = (d['price'] ?? 0).toDouble();

        if (status == 'cancelled') {
          cancelledAppointments++;
        } else {
          confirmedAppointments++;
          totalRevenue += price;
        }

        final key = DateFormat('yyyy-MM-dd').format(date);
        calendarData.putIfAbsent(
          key,
          () => {'appointments': 0, 'notes': '', 'isDayOff': false},
        );

        calendarData[key]!['appointments']++;
      }
    }
    debugPrint("DoctorId from app: $doctorId");

    /// 🔹 أيام العطل + الملاحظات
    final daysSnap = await FirebaseFirestore.instance
        .collection('doctor_days')
        .doc(doctorId)
        .collection('days')
        .get();

    for (var doc in daysSnap.docs) {
      final key = doc.id;
      calendarData.putIfAbsent(
        key,
        () => {'appointments': 0, 'notes': '', 'isDayOff': false},
      );

      calendarData[key]!['notes'] = doc['notes'] ?? '';
      calendarData[key]!['isDayOff'] = doc['isDayOff'] ?? false;
    }

    setState(() => loading = false);
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    });
    fetchCalendarData();
  }

  void prevMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    });
    fetchCalendarData();
  }

  /// ✅ شريط الإحصائيات
  Widget buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          statCard("المواعيد", totalAppointments.toString(), Icons.event),
          statCard(
            "المؤكدة",
            confirmedAppointments.toString(),
            Icons.check_circle,
          ),
          statCard("الملغاة", cancelledAppointments.toString(), Icons.cancel),
          statCard(
            "الدخل",
            "${totalRevenue.toStringAsFixed(0)} د",
            Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.teal, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<QueryDocumentSnapshot>> fetchAppointmentsForDay(
    DateTime date,
  ) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: dateKey)
        .get();

    return snap.docs;
  }

  void openDayDetails(DateTime date, Map<String, dynamic> data) async {
    final appointments = await fetchAppointmentsForDay(date);
    final notesController = TextEditingController(text: data['notes'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تفاصيل ${DateFormat('dd MMMM', 'ar').format(date)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ملاحظات اليوم'),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('مواعيد اليوم'),
                const SizedBox(height: 6),
                if (appointments.isEmpty)
                  const Text('لا توجد مواعيد')
                else
                  ...appointments.map((doc) {
                    final a = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(a['patientName'] ?? 'مريض'),
                        subtitle: Text('${a['time']} - ${a['status']}'),
                        trailing: Text('${a['price']} د'),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = DateFormat('yyyy-MM-dd').format(date);

              await FirebaseFirestore.instance
                  .collection('doctor_days')
                  .doc(doctorId)
                  .collection('days')
                  .doc(key)
                  .set({
                    'notes': notesController.text,
                    'isDayOff': data['isDayOff'] ?? false,
                  }, SetOptions(merge: true));

              Navigator.pop(context);
              fetchCalendarData(); // تحديث
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (doctorId == null) {
      return const Scaffold(
        body: Center(child: Text('لم يتم العثور على معرف الطبيب')),
      );
    }

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    ).weekday;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تقويم الطبيب (${DateFormat.MMMM('en').format(selectedMonth)})',
        ),
      ),
      body: Column(
        children: [
          buildStatsBar(), // ⭐ الإضافة الجديدة

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: prevMonth,
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  DateFormat('MMMM yyyy', 'en').format(selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: nextMonth,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: daysInMonth + firstWeekday - 1,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) return const SizedBox();

                final day = index - firstWeekday + 2;
                final date = DateTime(
                  selectedMonth.year,
                  selectedMonth.month,
                  day,
                );
                final key = DateFormat('yyyy-MM-dd').format(date);
                final data = calendarData[key] ?? {};

                Color bgColor;
                if (data['isDayOff'] == true) {
                  bgColor = Colors.orange.shade200;
                } else if ((data['appointments'] ?? 0) >= 5) {
                  bgColor = Colors.red.shade200;
                } else if ((data['appointments'] ?? 0) > 0) {
                  bgColor = Colors.green.shade200;
                } else {
                  bgColor = Colors.white;
                }

                return GestureDetector(
                  onTap: () => openDayDetails(date, data),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$day',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          if ((data['appointments'] ?? 0) > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${data['appointments']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),

                          if ((data['notes'] ?? '').toString().isNotEmpty)
                            const Icon(Icons.note, size: 14),

                          if (data['isDayOff'] == true)
                            const Icon(Icons.beach_access, size: 14),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
