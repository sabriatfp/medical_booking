import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// شاشة "مواعيد اليوم" للسكريتير
/// appointments schema (تلخيص):
/// - doctorId: String
/// - date: String (yyyy-MM-dd)  ← مفتاح اليوم
/// - time: String (HH:mm)       ← ترتيب Lexicographic صحيح
/// - status: requested | confirmed | checked_in | canceled | no_show
/// - patientName: String?
/// - price: number?
/// - آثار (سيتم تحديثها بحسب الإجراء):
///   - confirmedAt: Timestamp(server)
///   - confirmedBy: String(uid)
///   - checkedInAt: Timestamp(server)
///   - checkedInBy: String(uid)
///   - noShowAt: Timestamp(server)
///   - noShowBy: String(uid)
///
/// ملاحظات مهمة:
/// 1) القراءة/الكتابة تتطلّب Auth (حتى لو Anonymous) + isSecretaryFor(doctorId) في القواعد.
/// 2) قد يطلب Firestore فهرس مركّب عند where + orderBy (doctorId, date, time).
/// 3) السكرتير مسموح له فقط: تأكيد الحجز، Check‑in، أو وسم كـ No‑show.
/// 4) ممنوع تعديل الحقول الحساسة مثل doctorId/date/time/price عبر الواجهة.
class AppointmentsTodayScreen extends StatefulWidget {
  final String doctorId;
  const AppointmentsTodayScreen({super.key, required this.doctorId});

  @override
  State<AppointmentsTodayScreen> createState() =>
      _AppointmentsTodayScreenState();
}

class _AppointmentsTodayScreenState extends State<AppointmentsTodayScreen> {
  /// تتبع الوثائق الجاري تحديثها لتعطيل الأزرار وعرض لودر صغير
  final _busy = <String>{};

  /// افتراضيًا اليوم الحالي (بدون وقت)
  DateTime _selectedDay = DateTime.now();

  /// UID الحالي (قد يكون Anonymous)
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // نقصّ الوقت إلى بداية اليوم لضمان صيغة التاريخ
    _selectedDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    // Debug اختياري:
    // ignore: avoid_print
    print('>>> Secretary UID = $_uid, doctorId = ${widget.doctorId}');
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDay);

  /// استعلام: doctorId + date == اليوم، وترتيب حسب time (HH:mm)
  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final q = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('date', isEqualTo: _dateKey)
        .orderBy('time'); // قد يطلب فهرس مركّب (doctorId, date, time)
    return q.snapshots();
  }

  /// تحديث الحالة مع حقول أثر إضافية (ملتزمة بالقواعد)
  Future<void> _updateStatus(
    String id,
    Map<String, Object?> patch, {
    String? successMessage,
  }) async {
    try {
      setState(() => _busy.add(id));
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(id)
          .update(patch);
      if (!mounted) return;
      if (successMessage != null && successMessage.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on FirebaseException catch (e) {
      debugPrint('AppointmentsToday UPDATE ERROR: ${e.code} ${e.message}');
      if (!mounted) return;
      String msg = 'تعذّر تحديث الحالة';
      if (e.code == 'permission-denied') {
        msg = 'تعذّر تحديث الحالة: صلاحيات غير كافية.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذّر تحديث الحالة')));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _confirmBooking(String docId) async {
    await _updateStatus(docId, {
      // القواعد تسمح بهذه الحقول:
      // 'status', 'confirmedAt', 'confirmedBy'
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
      'confirmedBy': _uid,
    }, successMessage: 'تم تأكيد الحجز');
  }

  Future<void> _confirmCheckIn(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحضور'),
        content: const Text('هل تريد تأكيد حضور هذا الموعد (Check‑in)؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _updateStatus(docId, {
        // القواعد ستسمح الآن بإرسال هذه الحقول
        'status': 'checked_in',
        'checkedInAt': FieldValue.serverTimestamp(),
        'checkedInBy': _uid,
      }, successMessage: 'تم تأكيد الحضور (Check‑in)');
    }
  }

  Future<void> _confirmNoShow(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('وسم كغياب'),
        content: const Text('هل تريد وسم هذا الموعد كغياب (No‑show)؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _updateStatus(docId, {
        // القواعد تسمح بـ noShowAt/noShowBy
        'status': 'no_show',
        'noShowAt': FieldValue.serverTimestamp(),
        'noShowBy': _uid,
      }, successMessage: 'تم وسم الموعد كغياب');
    }
  }

  /// أزرار الحركة حسب الحالة:
  /// requested → تأكيد الحجز / غياب
  /// confirmed → Check‑in / غياب
  /// checked_in / canceled / no_show → لا أزرار
  List<Widget> _actionButtons(String docId, String status) {
    final isLoading = _busy.contains(docId);
    final List<Widget> btns = [];

    Widget buildBtn({
      required String text,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      bool filled = true,
    }) {
      final iconChild = isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18);

      final style = filled
          ? ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 40),
            )
          : ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(.12),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(0, 40),
            );

      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: ElevatedButton.icon(
          icon: iconChild,
          label: Text(text),
          style: style,
          onPressed: isLoading ? null : onTap,
        ),
      );
    }

    switch (status) {
      case 'requested':
      case 'pending': // دعم محتمل للحالة القديمة
        btns.add(
          buildBtn(
            text: 'تأكيد الحجز',
            icon: Icons.verified_outlined,
            color: Colors.blue,
            onTap: () => _confirmBooking(docId),
          ),
        );
        btns.add(
          buildBtn(
            text: 'غياب',
            icon: Icons.person_off_outlined,
            color: Colors.red,
            onTap: () => _confirmNoShow(docId),
            filled: false,
          ),
        );
        break;
      case 'confirmed':
        btns.add(
          buildBtn(
            text: 'Check‑in',
            icon: Icons.how_to_reg_outlined,
            color: Colors.green,
            onTap: () => _confirmCheckIn(docId),
          ),
        );
        btns.add(
          buildBtn(
            text: 'غياب',
            icon: Icons.person_off_outlined,
            color: Colors.red,
            onTap: () => _confirmNoShow(docId),
            filled: false,
          ),
        );
        break;
      default:
        // checked_in | canceled | no_show → لا أزرار
        break;
    }

    return btns;
  }

  /// تسمية عربية + ألوان حالة للـ Chip
  (String label, Color fg, Color bg) _statusStyle(String s, BuildContext ctx) {
    switch (s) {
      case 'requested':
      case 'pending':
        return (
          'بانتظار التأكيد',
          Colors.grey.shade700,
          Colors.grey.withOpacity(.12),
        );
      case 'confirmed':
        return ('مؤكد', Colors.blue, Colors.blue.withOpacity(.12));
      case 'checked_in':
        return ('حضر', Colors.green, Colors.green.withOpacity(.12));
      case 'canceled':
        return ('ملغى', Colors.red, Colors.red.withOpacity(.12));
      case 'no_show':
        return ('غياب', Colors.amber.shade800, Colors.amber.withOpacity(.16));
      default:
        final c = Theme.of(ctx).colorScheme.onSurface;
        return ('غير معروف', c, c.withOpacity(.08));
    }
  }

  String _todayText() => DateFormat('yyyy-MM-dd').format(_selectedDay);

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(
        () => _selectedDay = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // حماية بسيطة لو الشاشة فُتحت بدون Auth
    if (_uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('مواعيد اليوم')),
        body: const Center(
          child: Text(
            'لا تملك جلسة صالحة. الرجاء الدخول عبر كود السكرتير ثم إعادة المحاولة.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواعيد اليوم'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'اختر تاريخًا',
            onPressed: _pickDay,
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            // كشف أخطاء الصلاحيات بوضوح
            final err = snap.error.toString();
            debugPrint('AppointmentsToday STREAM ERROR: $err');
            final permDenied =
                err.contains('permission-denied') ||
                err.contains('PERMISSION_DENIED');
            return Center(
              child: Text(
                permDenied
                    ? 'لا تملك صلاحية الاطلاع على المواعيد لهذا الطبيب.\nتأكد من تسجيل الدخول كـ سكريتير لهذا الطبيب.'
                    : 'حدث خطأ أثناء جلب البيانات',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'لا توجد مواعيد في $_dateKey',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final docId = d.id;
              final patientName = (data['patientName'] ?? '').toString();
              final time = (data['time'] ?? '--:--').toString(); // HH:mm
              final price = (data['price'] is num)
                  ? (data['price'] as num).toDouble()
                  : null;
              final status = (data['status'] ?? 'requested').toString();
              final (label, fg, bg) = _statusStyle(status, context);

              final isLoading = _busy.contains(docId);

              return Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              time,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: fg.withOpacity(.25)),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (price != null)
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined, size: 18),
                                const SizedBox(width: 4),
                                Text('${price.toStringAsFixed(0)} د.ت'),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              patientName.isEmpty ? 'مريض' : patientName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // الأزرار (تمكين/تعطيل بحسب _busy)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: isLoading
                              ? const [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ]
                              : _actionButtons(docId, status),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 6),
            Text('تاريخ: ${_todayText()}'),
            const Spacer(),
            const Text('الإجراءات: تأكيد / Check‑in / غياب'),
          ],
        ),
      ),
    );
  }
}
