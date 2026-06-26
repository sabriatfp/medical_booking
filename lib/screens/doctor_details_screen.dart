import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import '../models/doctor.dart';
import 'slots_screen.dart';
import 'package:medical_booking/services/doctor_service.dart';

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
    final doctorId = widget.doctor.id;

    final doctorRef = FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId);

    // 1️⃣ قراءة وثيقة الطبيب (القراءة الأولى)
    final doctorSnap = await doctorRef.get();
    if (!doctorSnap.exists) {
      setState(() => loading = false);
      return;
    }

    final data = doctorSnap.data()!;
    scheduleData = data;

    // 2️⃣ استخراج البيانات اللازمة للـ Rolling
    final weeklyTemplate = Map<String, Map<String, dynamic>>.from(
      data['weeklyTemplate'] ?? {},
    );
    final slotDuration = data['slotDuration'] ?? 15;

    // 3️⃣ تحميل أيام العطل البعيدة
    final offSnap = await FirebaseFirestore.instance
        .collection('doctor_days_off')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    daysOff = offSnap.docs.map((d) => (d['date'] as String).trim()).toSet();

    if (scheduleData?['weeks'] == null || scheduleData!['weeks'].isEmpty) {
      // ✅✅✅ 4️⃣ هنا بالضبط نطبّق Rolling
      await DoctorService.normalizeRollingWeeks(
        doctorId: doctorId,
        weeklyTemplate: weeklyTemplate,
        exceptionalDaysOff: daysOff,
        slotDuration: slotDuration,
      );
    }
    // 5️⃣ إعادة قراءة وثيقة الطبيب بعد Rolling
    final refreshedSnap = await doctorRef.get();
    scheduleData = refreshedSnap.data();

    setState(() => loading = false);
  }

  // ===============================
  // ✅ Helpers
  // ===============================
  void _callDoctor(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openMaps(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _canBookDoctor() {
    return widget.doctor.isAvailable;
  }

  // ===============================
  // ✅ UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final d = widget.doctor;
    final now = DateTime.now().toUtc();

    bool isExpired = false;

    // ✅ إذا الاشتراك غير نشط
    if (d.subscriptionActive == false) {
      isExpired = true;
    }

    // ✅ إذا له تاريخ نهاية
    if (d.subscriptionEnd != null) {
      if (d.subscriptionEnd!.isBefore(now)) {
        isExpired = true;
      }
    }

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.doctorPrefix} ${widget.doctor.name}'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===============================
          // ✅ Card معلومات الطبيب
          // ===============================
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${t.doctorPrefix} ${widget.doctor.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      availabilityBadge(widget.doctor.isAvailable, t),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _localizedSpecialty(context),
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.doctor.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 14),
                      ),

                      if (widget.doctor.isPriceVisible &&
                          widget.doctor.price != null) ...[
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.attach_money,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.doctor.price!.toStringAsFixed(0)} د.ت',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===============================
          // ✅ Card الاتصال
          // ===============================
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: Text(widget.doctor.phone),
                  onTap: () => _callDoctor(widget.doctor.phone),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(widget.doctor.address),
                  onTap: () => _openMaps(widget.doctor.address),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ===============================
          // ✅ الحجز
          // ===============================
          Text(
            t.chooseDay,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          if (_canBookDoctor() && !isExpired)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {},
                child: Text(
                  t.bookAppointment,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  isExpired
                      ? t.subscriptionExpiredDoctor
                      : t.doctorNotAvailable,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 16),

          if (scheduleData?['weeks'] != null &&
              scheduleData!['weeks'].isNotEmpty)
            _buildDaysList(scheduleData!['weeks'], t)
          else
            Text(
              t.noAvailableAppointments,
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  String _localizedSpecialty(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;

    switch (lang) {
      case 'ar':
        return (widget.doctor.specialtyLabelAr?.isNotEmpty ?? false)
            ? widget.doctor.specialtyLabelAr!
            : (widget.doctor.specialtyLabelFr ?? '');
      case 'en':
        return (widget.doctor.specialtyLabelEn?.isNotEmpty ?? false)
            ? widget.doctor.specialtyLabelEn!
            : (widget.doctor.specialtyLabelFr ?? '');

      case 'fr':
      default:
        return widget.doctor.specialtyLabelFr ?? '';
    }
  }

  // ===============================
  // ✅ Widgets مساعدة
  // ===============================
  Widget availabilityBadge(bool isAvailable, AppLocalizations t) {
    return isAvailable
        ? _badge(t.available, Colors.green, Icons.check_circle)
        : _badge(t.notAvailable, Colors.red, Icons.cancel);
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList(List weeks, AppLocalizations t) {
    List allDays = [];
    for (var w in weeks) {
      allDays.addAll(w["days"]);
    }

    return Column(
      children: allDays.map<Widget>((day) {
        final date = (day["date"] as String).trim();
        final availableInWeeks = day["available"] == true;
        final full = day["full"] == true;
        final isDayOff = daysOff.contains(date);

        // ✅ القرار النهائي للحجز
        final now = DateTime.now().toUtc();

        bool isExpired = false;

        if (widget.doctor.subscriptionActive == false) {
          isExpired = true;
        }

        if (widget.doctor.subscriptionEnd != null) {
          if (widget.doctor.subscriptionEnd!.isBefore(now)) {
            isExpired = true;
          }
        }

        final canBook =
            widget.doctor.isAvailable &&
            availableInWeeks &&
            !full &&
            !isDayOff &&
            !isExpired;
        Color cardColor;
        String subtitle;

        if (isDayOff) {
          cardColor = Colors.orange.shade100;
          subtitle = t.doctorDayOff;
        } else if (!availableInWeeks) {
          cardColor = Colors.grey.shade200;
          subtitle = t.notAvailable;
        } else if (full) {
          cardColor = Colors.red.shade100;
          subtitle = t.full;
        } else {
          // ✅ الحالة الوحيدة القابلة للحجز
          cardColor = Colors.white;
          subtitle = t.available;
        }

        return Card(
          color: cardColor,
          child: ListTile(
            title: Text(date),
            subtitle: Text(subtitle),
            enabled: canBook,
            onTap: () {
              if (isExpired) {
                final t = AppLocalizations.of(context)!;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.doctorNotAvailable)));

                return;
              }

              if (!widget.doctor.isAvailable) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.doctorNotAvailable)));
                return;
              }

              if (canBook) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SlotsScreen(
                      doctor: widget.doctor,
                      date: date,
                      scheduleData: scheduleData,
                    ),
                  ),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
