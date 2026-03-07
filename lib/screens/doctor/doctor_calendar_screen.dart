import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// خدمة الطبيب لاستخراج doctorId تلقائيًا عند وضع "الطبيب"
import '../../services/doctor_service.dart';

class DoctorCalendarScreen extends StatefulWidget {
  /// في وضع الطبيب: اتركها null وسيتم استنتاج doctorId من الحساب
  /// في وضع السكرتير: مرّر doctorId + asSecretary: true
  final String? doctorId;
  final bool asSecretary;

  /// NEW: إخفاء الهيدر الداخلي (العنوان + السهم) داخل فضاء السكريتير
  final bool hideInnerHeader;

  const DoctorCalendarScreen({
    super.key,
    this.doctorId,
    this.asSecretary = false,
    this.hideInnerHeader = false, // الافتراضي: لا نخفي
  });

  @override
  State<DoctorCalendarScreen> createState() => _DoctorCalendarScreenState();
}

class _DoctorCalendarScreenState extends State<DoctorCalendarScreen> {
  // الشهر الحالي المعروض
  DateTime _selectedMonth = DateTime.now();

  // doctorId النهائي بعد الحلّ
  String? _resolvedDoctorId;

  // تحميل/خطأ
  bool _loading = true;
  String? _error;

  // بيانات التقويم
  final Map<String, Map<String, dynamic>> _calendarData = {};

  // ✅ إحصائيات الشهر
  int _totalAppointments = 0;
  int _confirmedAppointments = 0;
  int _cancelledAppointments = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _resolveDoctorId();
  }

  Future<void> _resolveDoctorId() async {
    try {
      if (widget.doctorId != null && widget.doctorId!.isNotEmpty) {
        _resolvedDoctorId = widget.doctorId;
      } else {
        // وضع الطبيب: استخرج المعرّف من الخدمة
        _resolvedDoctorId = await DoctorService().getDoctorId();
      }

      if (_resolvedDoctorId == null || _resolvedDoctorId!.isEmpty) {
        _error = 'لم يتم العثور على معرف الطبيب';
      } else {
        await _fetchCalendarData();
      }
    } catch (_) {
      _error = 'خطأ أثناء تحديد الطبيب';
    } finally {
      if (mounted) setState(() => _loading = false);
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

    // 🔹 المواعيد (نجلب جميع مواعيد الطبيب ثم نرشّح حسب الشهر على العميل)
    final apptSnap = await fs
        .collection('appointments')
        .where('doctorId', isEqualTo: _resolvedDoctorId)
        .get();

    for (var doc in apptSnap.docs) {
      final d = doc.data();
      final dateStr = (d['date'] ?? '').toString();
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final sameMonth =
          (date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month);
      if (!sameMonth) continue;

      _totalAppointments++;

      // معالجة السعر كـ num (int/double)
      double price = 0;
      final anyPrice = d['price'];
      if (anyPrice is int) price = anyPrice.toDouble();
      if (anyPrice is double) price = anyPrice;

      // دعم كلا الصيغتين: canceled/cancelled
      final status = (d['status'] ?? 'confirmed').toString();
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

    // 🔹 أيام العطل + الملاحظات
    // بنية: doctor_days/{doctorId}/days/{yyyy-MM-dd} = { notes: string, isDayOff: bool }
    final daysSnap = await fs
        .collection('doctor_days')
        .doc(_resolvedDoctorId)
        .collection('days')
        .get();

    for (var doc in daysSnap.docs) {
      final key = doc.id;
      _calendarData.putIfAbsent(
        key,
        () => {'appointments': 0, 'notes': '', 'isDayOff': false},
      );

      final data = doc.data();
      _calendarData[key]!['notes'] = (data['notes'] ?? '').toString();
      _calendarData[key]!['isDayOff'] = data['isDayOff'] == true;
    }

    if (mounted) setState(() => _loading = false);
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
    // ignore: discarded_futures
    _fetchCalendarData();
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
    // ignore: discarded_futures
    _fetchCalendarData();
  }

  /// ✅ شريط الإحصائيات
  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _statCard("المواعيد", _totalAppointments.toString(), Icons.event),
          _statCard(
            "المؤكدة",
            _confirmedAppointments.toString(),
            Icons.check_circle,
          ),
          _statCard("الملغاة", _cancelledAppointments.toString(), Icons.cancel),
          _statCard(
            "الدخل",
            "${_totalRevenue.toStringAsFixed(0)} د",
            Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
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

  Future<List<QueryDocumentSnapshot>> _fetchAppointmentsForDay(
    DateTime date,
  ) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: _resolvedDoctorId)
        .where('date', isEqualTo: dateKey)
        .get();

    return snap.docs;
  }

  void _openDayDetails(DateTime date, Map<String, dynamic> data) async {
    final appointments = await _fetchAppointmentsForDay(date);
    final notesController = TextEditingController(
      text: (data['notes'] ?? '').toString(),
    );

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

                    // عرض آمن للقيم
                    final name = (a['patientName'] ?? 'مريض').toString();
                    final time = (a['time'] ?? '--:--').toString();
                    final status = (a['status'] ?? '').toString();
                    num priceAny = (a['price'] is num) ? a['price'] as num : 0;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(name),
                        subtitle: Text('$time - $status'),
                        trailing: Text('${priceAny.toStringAsFixed(0)} د'),
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
                  .doc(_resolvedDoctorId)
                  .collection('days')
                  .doc(key)
                  .set({
                    'notes': notesController.text,
                    'isDayOff': data['isDayOff'] ?? false,
                  }, SetOptions(merge: true));

              if (mounted) Navigator.pop(context);
              // ignore: discarded_futures
              _fetchCalendarData();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      // عند تفعيل hideInnerHeader نخفي AppBar حتى في حالة الخطأ
      return Scaffold(
        appBar: widget.hideInnerHeader
            ? null
            : AppBar(title: const Text('تقويم الطبيب')),
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
      // ❗️لا نعرض AppBar داخلي عندما نكون في فضاء السكريتير
      appBar: widget.hideInnerHeader
          ? null
          : AppBar(
              title: Text(
                'تقويم الطبيب (${DateFormat.MMMM('fr').format(_selectedMonth)})',
              ),
            ),
      body: Column(
        children: [
          _buildStatsBar(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'الشهر السابق',
                ),
                Text(
                  DateFormat('MMMM yyyy', 'en').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'الشهر التالي',
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
