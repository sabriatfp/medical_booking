import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import '../../services/doctor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorCalendarScreen extends StatefulWidget {
  final String? doctorId;
  final bool asSecretary;
  final bool hideInnerHeader;

  const DoctorCalendarScreen({
    super.key,
    this.doctorId,
    this.asSecretary = false,
    this.hideInnerHeader = false,
  });

  @override
  State<DoctorCalendarScreen> createState() => _DoctorCalendarScreenState();
}

class _DoctorCalendarScreenState extends State<DoctorCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  String? _resolvedDoctorId;

  bool _loading = true;
  String? _error;

  final Map<String, Map<String, dynamic>> _calendarData = {};
  int _totalAppointments = 0;
  int _confirmedAppointments = 0;
  int _cancelledAppointments = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDoctorCalendar();
    });
  }

  Future<void> _initDoctorCalendar() async {
    try {
      _resolvedDoctorId = widget.doctorId?.isNotEmpty == true
          ? widget.doctorId
          : await DoctorService().getDoctorId();
      // ✅ ضع الـ print هنا
      print("UID: ${FirebaseAuth.instance.currentUser?.uid}");
      print("DoctorId: $_resolvedDoctorId");

      if (_resolvedDoctorId == null) {
        if (!mounted) return;
        final t = AppLocalizations.of(context)!;
        setState(() {
          _error = t.doctorIdNotFound;
          _loading = false;
        });
        return;
      }

      await _fetchCalendarData();
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      setState(() {
        _error = t.errorFindingDoctor;
        _loading = false;
      });
    }
  }

  Future<void> _fetchCalendarData() async {
    if (_resolvedDoctorId == null) return;

    setState(() => _loading = true);

    _calendarData.clear();
    _totalAppointments = 0;
    _confirmedAppointments = 0;
    _cancelledAppointments = 0;
    _totalRevenue = 0;

    final fs = FirebaseFirestore.instance;

    try {
      // جلب المواعيد
      final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

      final apptSnap = await fs
          .collection('appointments')
          .where('doctorId', isEqualTo: _resolvedDoctorId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateTime', isLessThan: Timestamp.fromDate(end))
          .get();

      for (var doc in apptSnap.docs) {
        final data = doc.data();
        DateTime? date;

        final raw = data['dateTime'];

        if (raw is Timestamp) {
          date = raw.toDate();
        } else if (raw is String) {
          date = DateTime.tryParse(raw);
        }

        if (date == null) continue;

        if (date.year != _selectedMonth.year ||
            date.month != _selectedMonth.month)
          continue;

        _totalAppointments++;

        double price = 0;
        final anyPrice = data['price'];
        if (anyPrice is int) price = anyPrice.toDouble();
        if (anyPrice is double) price = anyPrice;

        final status = (data['status'] ?? '').toString().toLowerCase();
        final isCanceled = status == 'canceled' || status == 'cancelled';

        if (isCanceled) {
          _cancelledAppointments++;
        } else {
          _confirmedAppointments++;
          _totalRevenue += price;
        }

        final key = DateFormat('yyyy-MM-dd').format(date);
        _calendarData.putIfAbsent(
          key,
          () => {'appointments': 0, 'notes': '', 'isDayOff': false},
        );
        _calendarData[key]!['appointments'] =
            (_calendarData[key]!['appointments'] ?? 0) + 1;
      }

      // جلب أيام العمل/عطلة الطبيب
      final daysSnap = await fs
          .collection('doctor_days')
          .doc(_resolvedDoctorId)
          .collection('days')
          .get();

      for (var doc in daysSnap.docs) {
        final key = doc.id;
        final data = doc.data();

        _calendarData.putIfAbsent(
          key,
          () => {'appointments': 0, 'notes': '', 'isDayOff': false},
        );

        _calendarData[key]!['notes'] = (data['notes'] ?? '').toString();
        _calendarData[key]!['isDayOff'] = data['isDayOff'] == true;
      }
    } catch (e) {
      _error = AppLocalizations.of(context)!.errorFindingDoctor;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
    _fetchCalendarData();
  }

  Widget _buildStatsBar() {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _statCard(t.appointments, _totalAppointments.toString(), Icons.event),
          _statCard(
            t.confirmedAppointments,
            _confirmedAppointments.toString(),
            Icons.check_circle,
          ),
          _statCard(
            t.cancelledAppointments,
            _cancelledAppointments.toString(),
            Icons.cancel,
          ),
          // _statCard(
          //  t.revenue,
          // "${_totalRevenue.toStringAsFixed(0)} د",
          // Icons.attach_money,
          //),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
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

  Future<List<QueryDocumentSnapshot>> _fetchAppointmentsForDay(
    DateTime date,
  ) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: _resolvedDoctorId)
        .where('date', isEqualTo: key)
        .get();
    return snap.docs;
  }

  void _openDayDetails(DateTime date, Map<String, dynamic> data) async {
    final t = AppLocalizations.of(context)!;
    final appointments = await _fetchAppointmentsForDay(date);
    final notesController = TextEditingController(text: data['notes'] ?? "");
    final locale = Localizations.localeOf(context).toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "${t.dayDetails} ${DateFormat('dd MMMM yyyy', locale).format(date)}",
        ),

        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.dayNotes),
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
                Text(t.dayAppointments),
                const SizedBox(height: 6),
                if (appointments.isEmpty)
                  Text(t.noAppointments)
                else
                  ...appointments.map((doc) {
                    final a = doc.data() as Map<String, dynamic>;
                    final name = a['patientName'] ?? t.patient;
                    final time = a['time'] ?? '--:--';
                    final status = a['status'] ?? '';
                    final price = (a['price'] is num)
                        ? (a['price'] as num).toDouble()
                        : 0;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(name),
                        subtitle: Text("$time - $status"),
                        trailing: Text("${price.toStringAsFixed(0)} د"),
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
            child: Text(t.close),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = DateFormat('yyyy-MM-dd').format(date);
              await FirebaseFirestore.instance
                  .collection('doctor_days')
                  .doc(_resolvedDoctorId)
                  .collection('days')
                  .doc(key)
                  .set({
                    'notes': notesController.text,
                    'isDayOff': data['isDayOff'] ?? false,
                  }, SetOptions(merge: true));
              if (mounted) Navigator.pop(context);
              _fetchCalendarData();
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error != null) {
      return Scaffold(
        appBar: widget.hideInnerHeader
            ? null
            : AppBar(title: Text(t.doctorCalendar)),
        body: Center(child: Text(_error!)),
      );
    }

    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    ).weekday;

    return Scaffold(
      appBar: widget.hideInnerHeader
          ? null
          : AppBar(title: Text("${t.doctorCalendar} ")),
      body: Column(
        children: [
          _buildStatsBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: t.prevMonth,
                ),

                Text(
                  DateFormat('MMMM yyyy', locale).format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: t.nextMonth,
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
                  _selectedMonth.year,
                  _selectedMonth.month,
                  day,
                );
                final key = DateFormat('yyyy-MM-dd').format(date);
                final data = _calendarData[key] ?? {};

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
                  onTap: () => _openDayDetails(date, data),
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
                        children: [
                          Text(
                            "$day",
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
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${data['appointments']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          if ((data['notes'] ?? "").toString().isNotEmpty)
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
