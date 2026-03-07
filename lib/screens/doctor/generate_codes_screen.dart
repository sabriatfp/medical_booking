// lib/screens/doctor/generate_codes_screen.dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// شاشة توليد/إدارة أكواد السكريتير
/// المسار الخاص: /doctors/{doctorId}/secretary_codes/{codeId}
/// المسار العام:  /secretary_codes_public/{codeId}
/// docId = code (مثال: SEC-AB23K7)
/// fields (خاص):
///   - code: String
///   - doctorId: String
///   - active: bool
///   - createdAt: serverTimestamp()
///   - expiresAt: Timestamp? (اختياري)
///   - createdBy: String (uid)
/// fields (عام):
///   - code: String
///   - doctorId: String
///   - active: bool
///   - createdAt: serverTimestamp()  // مطابقة للقواعد المصحّحة
///   - expiresAt: Timestamp? (اختياري)
class GenerateCodesScreen extends StatefulWidget {
  final String doctorId;

  const GenerateCodesScreen({super.key, required this.doctorId});

  @override
  State<GenerateCodesScreen> createState() => _GenerateCodesScreenState();
}

class _GenerateCodesScreenState extends State<GenerateCodesScreen> {
  final _db = FirebaseFirestore.instance;

  /// مرجع الكولكشن تحت الطبيب الحالي (خاص)
  CollectionReference<Map<String, dynamic>> get _codesCol => _db
      .collection('doctors')
      .doc(widget.doctorId)
      .collection('secretary_codes');

  Stream<QuerySnapshot<Map<String, dynamic>>> _codesStream() {
    // لم نعد نحتاج where('doctorId') لأننا تحت مسار الطبيب مباشرة.
    return _codesCol.orderBy('createdAt', descending: true).snapshots();
  }

  // توليد كود فريد بالشكل SEC-XXXXXX مع استبعاد حروف اللبس (I,O,0,1)
  Future<String> _generateUniqueCode({int length = 6}) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random.secure();

    String gen() =>
        List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();

    // نحاول عدّة مرات لتفادي التعارض النادر
    for (int i = 0; i < 8; i++) {
      final candidate = 'SEC-${gen()}';
      final exists = await _codesCol.doc(candidate).get();
      if (!exists.exists) return candidate;
    }
    throw Exception('تعذر توليد كود فريد، أعد المحاولة لاحقًا.');
  }

  /// تحديث المستند العام (secretary_codes_public) بأمان
  Future<void> _publicUpdate(String codeId, Map<String, dynamic> data) async {
    try {
      await _db.collection('secretary_codes_public').doc(codeId).update(data);
    } catch (_) {
      // تجاهل لو الوثيقة العامة غير موجودة (قديمة مثلاً)
    }
  }

  /// حذف المستند العام بأمان
  Future<void> _publicDelete(String codeId) async {
    try {
      await _db.collection('secretary_codes_public').doc(codeId).delete();
    } catch (_) {
      // تجاهل لو غير موجود
    }
  }

  Future<void> _createCodeDialog() async {
    DateTime? pickedExpiry;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> pickExpiry() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: ctx,
                initialDate: now.add(const Duration(days: 7)),
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                final endOfDay = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  23,
                  59,
                  59,
                );
                setLocalState(() => pickedExpiry = endOfDay);
              }
            }

            return AlertDialog(
              title: const Text('إنشاء كود سكريتير'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('يمكنك إضافة تاريخ صلاحية اختياريًا.'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pickedExpiry == null
                              ? 'بدون صلاحية (يعمل دائمًا حتى تعطيله يدويًا)'
                              : 'الصلاحية حتى: ${pickedExpiry.toString().substring(0, 16)}',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: pickExpiry,
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('تحديد التاريخ'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('إنشاء'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      try {
        // 1) التحقق من تسجيل الدخول
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          throw Exception('المستخدم غير مسجّل دخول.');
        }

        // 2) التحقق من ملكية الطبيب عبر ownerUid
        final docSnap = await _db
            .collection('doctors')
            .doc(widget.doctorId)
            .get();
        if (!docSnap.exists) {
          throw Exception('ملف الطبيب غير موجود.');
        }
        final doctorData = docSnap.data() as Map<String, dynamic>;
        final ownerUid = doctorData['ownerUid'] as String?;
        if (ownerUid == null || ownerUid != uid) {
          throw Exception('لا تملك صلاحية إنشاء كود لهذا الطبيب.');
        }

        // 3) تحقق من تاريخ الصلاحية إن تم اختياره
        if (pickedExpiry != null &&
            pickedExpiry!.isBefore(
              DateTime.now().add(const Duration(minutes: 1)),
            )) {
          throw Exception('تاريخ الصلاحية يجب أن يكون لاحقًا للوقت الحالي.');
        }

        // 4) توليد كود فريد (docId = code)
        final code = await _generateUniqueCode();

        // 5) بناء البيانات (مطابقة للقواعد)
        final privateRef = _db
            .collection('doctors')
            .doc(widget.doctorId)
            .collection('secretary_codes')
            .doc(code);

        final publicRef = _db.collection('secretary_codes_public').doc(code);

        final Map<String, dynamic> privateData = {
          'code': code,
          'doctorId': widget.doctorId,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          if (pickedExpiry != null)
            'expiresAt': Timestamp.fromDate(pickedExpiry!),
          'createdBy': uid,
        };

        final Map<String, dynamic> publicData = {
          'code': code,
          'doctorId': widget.doctorId,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(), // مهم للقواعد
          if (pickedExpiry != null)
            'expiresAt': Timestamp.fromDate(pickedExpiry!),
        };

        // DEBUG: اطبع المسارات والبيانات قبل الكتابة
        final cleanPrivate = Map<String, dynamic>.from(privateData)
          ..removeWhere((k, v) => v == null);
        final cleanPublic = Map<String, dynamic>.from(publicData)
          ..removeWhere((k, v) => v == null);
        // اطبع الـ uid والـ ownerUid أيضًا لتأكيد الهوية
        // (لن تظهر في الواجهة، فقط في الـ console)
        // ignore: avoid_print
        print('>>> DEBUG: currentUser.uid = $uid');
        // ignore: avoid_print
        print('>>> DEBUG: doctor.ownerUid = $ownerUid');
        // ignore: avoid_print
        print('>>> WRITE PATH (private) = ${privateRef.path}');
        // ignore: avoid_print
        print('>>> WRITE DATA (private) = $cleanPrivate');
        // ignore: avoid_print
        print('>>> WRITE PATH (public)  = ${publicRef.path}');
        // ignore: avoid_print
        print('>>> WRITE DATA (public)  = $cleanPublic');

        // 6) الكتابة — Batch
        final batch = _db.batch();
        batch.set(privateRef, privateData);
        batch.set(publicRef, publicData);
        await batch.commit();

        // 7) مباشرةً: عرض Dialog يحتوي QR + الكود النصّي
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => CodeQrDialog(code: code, expiresAt: pickedExpiry),
        );

        // SnackBar بسيط بعد الإغلاق
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم إنشاء الكود: $code')));
      } on FirebaseException catch (e, st) {
        debugPrint(
          'CreateSecretaryCode FIREBASE ERROR: ${e.code} ${e.message}',
        );
        debugPrint('STACK: $st');
        if (!mounted) return;
        String msg = 'تعذّر إنشاء الكود.';
        if (e.code == 'permission-denied') {
          msg =
              'تعذّر إنشاء الكود: لا تملك صلاحية الكتابة (permission-denied).';
        } else if (e.code == 'unavailable') {
          msg = 'تعذّر إنشاء الكود: مشكلة اتصال. حاول لاحقًا.';
        } else if (e.code == 'already-exists') {
          msg = 'هذا الكود موجود بالفعل. أعد المحاولة.';
        } else if (e.code == 'failed-precondition') {
          msg = 'تعذّر إنشاء الكود: تحقق من القواعد/الفهارس.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } catch (e, st) {
        debugPrint('CreateSecretaryCode ERROR: $e');
        debugPrint('STACK: $st');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذّر إنشاء الكود: $e')));
      }
    }
  }

  Future<void> _toggleActive(
    DocumentReference<Map<String, dynamic>> ref,
    bool current,
  ) async {
    try {
      await ref.update({'active': !current});
      await _publicUpdate(ref.id, {'active': !current}); // مزامنة العامة
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذّر التحديث: ${e.code}')));
    }
  }

  Future<void> _editExpiry(
    DocumentReference<Map<String, dynamic>> ref,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final initial = (current == null || current.isBefore(now))
        ? now.add(const Duration(days: 7))
        : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    final endOfDay = DateTime(
      picked.year,
      picked.month,
      picked.day,
      23,
      59,
      59,
    );

    try {
      final ts = Timestamp.fromDate(endOfDay);
      await ref.update({'expiresAt': ts});
      await _publicUpdate(ref.id, {'expiresAt': ts}); // مزامنة العامة
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث تاريخ الصلاحية')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذّر التحديث: ${e.code}')));
    }
  }

  Future<void> _clearExpiry(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await ref.update({'expiresAt': FieldValue.delete()});
      await _publicUpdate(ref.id, {
        'expiresAt': FieldValue.delete(),
      }); // مزامنة العامة
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إزالة تاريخ الصلاحية')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذّر التحديث: ${e.code}')));
    }
  }

  Future<void> _deleteCode(DocumentReference<Map<String, dynamic>> ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الكود'),
        content: const Text('هل تريد بالتأكيد حذف هذا الكود؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final codeId = ref.id;
        await ref.delete();
        await _publicDelete(codeId); // حذف من العامة
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الكود')));
      } on FirebaseException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذّر الحذف: ${e.code}')));
      }
    }
  }

  String _statusLabel(Map<String, dynamic> data) {
    final active = (data['active'] ?? true) as bool;
    final expiresTs = data['expiresAt'] as Timestamp?;
    final now = DateTime.now();
    final expired = (expiresTs != null)
        ? expiresTs.toDate().isBefore(now)
        : false;

    if (!active) return 'غير مفعّل';
    if (expired) return 'منتهي الصلاحية';
    return 'فعّال';
  }

  Color _statusColor(Map<String, dynamic> data) {
    final label = _statusLabel(data);
    switch (label) {
      case 'فعّال':
        return Colors.green;
      case 'غير مفعّل':
        return Colors.grey;
      case 'منتهي الصلاحية':
        return Colors.amber.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أكواد السكريتير'),
        actions: [
          IconButton(
            tooltip: 'إنشاء كود جديد',
            onPressed: _createCodeDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCodeDialog,
        icon: const Icon(Icons.add),
        label: const Text('إنشاء كود'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _codesStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('حدث خطأ أثناء جلب الأكواد'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _EmptyView();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final ref = d.reference;
              final data = d.data();
              final code = (data['code'] ?? d.id).toString();
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
              final active = (data['active'] ?? true) as bool;

              final statusText = _statusLabel(data);
              final statusColor = _statusColor(data);

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
                          Flexible(
                            child: SelectableText(
                              code,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // شارة الحالة
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: statusColor.withOpacity(.25),
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'نسخ الكود',
                            icon: const Icon(Icons.copy_all_rounded),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: code),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تم نسخ الكود: $code')),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // التاريخ + أزرار بدون Overflow
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.event_outlined, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                createdAt == null
                                    ? '—'
                                    : 'أنشئ: ${createdAt.toString().substring(0, 16)}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.schedule_outlined, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                expiresAt == null
                                    ? 'بدون صلاحية'
                                    : 'ينتهي: ${expiresAt.toString().substring(0, 16)}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editExpiry(ref, expiresAt),
                                  icon: const Icon(
                                    Icons.edit_calendar_outlined,
                                  ),
                                  label: const Text('تعديل الصلاحية'),
                                ),
                                TextButton(
                                  onPressed: () => _clearExpiry(ref),
                                  child: const Text('إزالة الصلاحية'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(
                                active
                                    ? Icons.pause_circle_filled_outlined
                                    : Icons.play_circle_fill_outlined,
                              ),
                              label: Text(active ? 'تعطيل' : 'تفعيل'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: active
                                    ? Colors.grey
                                    : Colors.green,
                              ),
                              onPressed: () => _toggleActive(ref, active),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('حذف'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => _deleteCode(ref),
                            ),
                          ),
                        ],
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

class CodeQrDialog extends StatelessWidget {
  final String code; // مثل: SEC-AB23K7
  final DateTime? expiresAt;

  const CodeQrDialog({super.key, required this.code, this.expiresAt});

  @override
  Widget build(BuildContext context) {
    final safeCode = (code).trim();
    final hasCode = safeCode.isNotEmpty;

    final size = MediaQuery.of(context).size;
    // حجم مناسب للـ Dialog
    final double qrSize = (size.shortestSide * 0.6).clamp(140.0, 260.0);

    final expireText = (expiresAt == null)
        ? 'بدون صلاحية'
        : 'ينتهي: ${expiresAt.toString().substring(0, 16)}';

    // 1) تحقّق من صلاحية الـ QR قبل الرسم
    QrValidationResult? validationResult;
    if (hasCode) {
      validationResult = QrValidator.validate(
        data: safeCode,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
    }

    final isValid =
        hasCode &&
        validationResult != null &&
        validationResult.status == QrValidationStatus.valid;

    return AlertDialog(
      title: const Text('رمز دخول السكريتير (QR)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2) إذا صالح: ارسم باستخدام QrPainter.withQr بدون أنماط إضافية
            if (isValid)
              Container(
                width: qrSize,
                height: qrSize,
                padding: const EdgeInsets.all(10), // ← التصحيح هنا
                color: Colors.white, // خلفية بيضاء لضمان تباين واضح
                child: CustomPaint(
                  size: Size.square(qrSize - 20),
                  painter: QrPainter.withQr(
                    qr: validationResult.qrCode!,
                    gapless: true,
                    color: Colors.black,
                    emptyColor: Colors.white,
                  ),
                ),
              )
            else
              Container(
                width: qrSize,
                height: qrSize,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: Text(
                  hasCode
                      ? 'تعذّر توليد QR لهذا الكود.\n(تحقق من الحزمة/الإصدار)'
                      : 'لا يوجد كود صالح لعرضه',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),

            const SizedBox(height: 12),

            // الكود النصي + النسخ
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    hasCode ? safeCode : '—',
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'نسخ الكود',
                  onPressed: hasCode
                      ? () async {
                          await Clipboard.setData(
                            ClipboardData(text: safeCode),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم نسخ الكود: $safeCode'),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.copy_all_rounded),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    expireText,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تم'),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 64, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              'لا توجد أكواد سكريتير بعد.\nاضغط "إنشاء كود" لإضافة كود جديد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
