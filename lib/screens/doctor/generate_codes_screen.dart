//E:\Users\khawla\medical_booking\lib\screens\doctor\generate_codes_screen.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateCodesScreen extends StatefulWidget {
  final String doctorId;
  const GenerateCodesScreen({super.key, required this.doctorId});

  @override
  State<GenerateCodesScreen> createState() => _GenerateCodesScreenState();
}

class _GenerateCodesScreenState extends State<GenerateCodesScreen> {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _codesCol() {
    return _db
        .collection('doctors')
        .doc(widget.doctorId)
        .collection('secretary_codes');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _codesStream() {
    return _codesCol().orderBy('createdAt', descending: true).snapshots();
  }

  // ----------------------
  //  Create Code Dialog
  // ----------------------
  Future<void> _publicUpdate(String code, Map<String, dynamic> data) async {
    final db = FirebaseFirestore.instance;

    try {
      await db.collection('secretary_codes_public').doc(code).update(data);
    } catch (e) {
      debugPrint("publicUpdate error: $e");
    }
  }

  Future<String> _generateUniqueCode() async {
    final db = FirebaseFirestore.instance;

    // مولد رموز — مثال: 6 أحرف/أرقام
    String _randomCode() {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rnd = DateTime.now().microsecondsSinceEpoch;
      final buffer = StringBuffer();
      final r = rnd % chars.length;

      for (int i = 0; i < 6; i++) {
        buffer.write(chars[(r + i * 7) % chars.length]);
      }
      return buffer.toString();
    }

    while (true) {
      final code = _randomCode();

      // تحقّق في المجموعة العامة
      final pub = await db.collection('secretary_codes_public').doc(code).get();

      if (!pub.exists) {
        return code; // ✅ صالح
      }
    }
  }

  Future<void> _createCodeDialog() async {
    final t = AppLocalizations.of(context)!;
    DateTime? pickedExpiry;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> pickExpiry() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: ctx,
                initialDate: now.add(const Duration(days: 7)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(
                  () => pickedExpiry = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    23,
                    59,
                    59,
                  ),
                );
              }
            }

            return AlertDialog(
              // ✅ العنوان في الوسط
              title: Center(
                child: Text(
                  t.createSecretaryCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ سطر الصلاحية (لا يتمدد أكثر من اللازم)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.timer_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pickedExpiry == null
                              ? t.noExpiry
                              : "${t.expiresAt}: ${pickedExpiry.toString().substring(0, 16)}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ✅ زر اختيار التاريخ في سطر مستقل (أجمل + أوضح)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: pickExpiry,
                      icon: const Icon(Icons.edit_calendar_outlined),
                      label: Text(t.pickDate),
                    ),
                  ),
                ],
              ),

              actionsAlignment: MainAxisAlignment.spaceBetween,

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(t.create),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      await _createCode(pickedExpiry);
    }
  }

  // ---------------------------
  // إنشاء الكود فعلياً بعد الموافقة
  // ---------------------------
  Future<void> _createCode(DateTime? pickedExpiry) async {
    final t = AppLocalizations.of(context)!;

    try {
      // 1) التحقق من المستخدم
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception(t.userNotLogged);

      // 2) جلب ملف الطبيب للتحقق من ownerUid
      final doctorSnap = await _db
          .collection('doctors')
          .doc(widget.doctorId)
          .get();
      if (!doctorSnap.exists) throw Exception(t.doctorFileNotFound);

      final doctorData = doctorSnap.data()!;
      final ownerUid = doctorData['ownerUid'];
      if (ownerUid == null || ownerUid != uid) {
        throw Exception(t.noPermissionForThisDoctor);
      }

      // 3) التحقق من تاريخ الصلاحية
      if (pickedExpiry != null &&
          pickedExpiry.isBefore(
            DateTime.now().add(const Duration(minutes: 1)),
          )) {
        throw Exception(t.expiryMustBeFuture);
      }

      // 4) توليد كود فريد
      final code = await _generateUniqueCode();

      // 5) مسارات الكتابة
      final privateRef = _db
          .collection('doctors')
          .doc(widget.doctorId)
          .collection('secretary_codes')
          .doc(code);

      final publicRef = _db.collection('secretary_codes_public').doc(code);

      final privateData = {
        'code': code,
        'doctorId': widget.doctorId,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        if (pickedExpiry != null) 'expiresAt': Timestamp.fromDate(pickedExpiry),
        'createdBy': uid,
      };

      final publicData = {
        'code': code,
        'doctorId': widget.doctorId,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        if (pickedExpiry != null) 'expiresAt': Timestamp.fromDate(pickedExpiry),
      };

      // 6) Batch write
      final batch = _db.batch();
      batch.set(privateRef, privateData);
      batch.set(publicRef, publicData);
      await batch.commit();

      // 7) عرض QR
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => CodeQrDialog(code: code, expiresAt: pickedExpiry),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${t.codeCreated}: $code")));
    }
    // أخطاء Firebase
    catch (e) {
      final t = AppLocalizations.of(context)!;
      String msg = t.generalFailure;

      if (e is FirebaseException) {
        switch (e.code) {
          case 'permission-denied':
            msg = t.permissionDenied;
            break;
          case 'unavailable':
            msg = t.networkError;
            break;
          case 'already-exists':
            msg = t.codeAlreadyExists;
            break;
        }
      } else if (e is Exception) {
        msg = e.toString().replaceFirst('Exception: ', '');
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _publicDelete(String code) async {
    final db = FirebaseFirestore.instance;

    try {
      await db.collection('secretary_codes_public').doc(code).delete();
    } catch (e) {
      debugPrint("publicDelete error: $e");
    }
  }

  // ---------------------------
  // تفعيل / تعطيل الكود
  // ---------------------------
  Future<void> _toggleActive(DocumentReference ref, bool current) async {
    final t = AppLocalizations.of(context)!;

    try {
      await ref.update({'active': !current});
      await _publicUpdate(ref.id, {'active': !current});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${t.updateFailed}: $e")));
    }
  }

  // ---------------------------
  // تعديل تاريخ الصلاحية
  // ---------------------------
  Future<void> _editExpiry(DocumentReference ref, DateTime? current) async {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();

    final initial = (current == null || current.isBefore(now))
        ? now.add(const Duration(days: 7))
        : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
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
      await _publicUpdate(ref.id, {'expiresAt': ts});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.expiryUpdated)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${t.updateFailed}: $e")));
    }
  }

  // ---------------------------
  // إزالة الصلاحية
  // ---------------------------
  Future<void> _clearExpiry(DocumentReference ref) async {
    final t = AppLocalizations.of(context)!;

    try {
      await ref.update({'expiresAt': FieldValue.delete()});
      await _publicUpdate(ref.id, {'expiresAt': FieldValue.delete()});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.expiryRemoved)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${t.updateFailed}: $e")));
    }
  }

  // ---------------------------
  // حذف الكود
  // ---------------------------
  Future<void> _deleteCode(DocumentReference ref) async {
    final t = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.deleteCode),
        content: Text(t.deleteCodeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final codeId = ref.id;
      await ref.delete();
      await _publicDelete(codeId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.codeDeleted)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${t.deleteFailed}: $e")));
    }
  }

  // ---------------------------
  // لاصقة الحالة (مترجمة)
  // ---------------------------
  String _statusLabel(Map<String, dynamic> data) {
    final t = AppLocalizations.of(context)!;

    final active = data['active'] == true;
    final expires = data['expiresAt'] as Timestamp?;
    final expired =
        expires != null && expires.toDate().isBefore(DateTime.now());

    if (!active) return t.statusInactive;
    if (expired) return t.statusExpired;
    return t.statusActive;
  }

  Color _statusColor(Map<String, dynamic> data) {
    final label = _statusLabel(data);

    if (label == AppLocalizations.of(context)!.statusActive) {
      return const Color.fromARGB(255, 153, 218, 155);
    }
    if (label == AppLocalizations.of(context)!.statusInactive) {
      return Colors.grey;
    }
    if (label == AppLocalizations.of(context)!.statusExpired) {
      return const Color.from(alpha: 1, red: 0.706, green: 0.6, blue: 0.671);
    }

    return Colors.blueGrey;
  }

  // ---------------------------
  // واجهة الشاشة
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.secretaryCodes),
        actions: [
          IconButton(
            tooltip: t.createNewCode,
            onPressed: _createCodeDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCodeDialog,
        icon: const Icon(Icons.add),
        label: Text(t.createCode),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _codesStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text(t.loadingFailed));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const _EmptyView();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              return _buildCodeCard(data, d.reference);
            },
          );
        },
      ),
    );
  }

  // ---------------------------
  // بطاقة الكود (مترجمة)
  // ---------------------------
  Widget _buildCodeCard(Map<String, dynamic> data, DocumentReference ref) {
    final t = AppLocalizations.of(context)!;

    final code = (data['code'] ?? ref.id).toString();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    final active = data['active'] == true;

    final statusText = _statusLabel(data);
    final statusColor = _statusColor(data);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 🔹 Header
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(.25)),
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

                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${t.copied}: $code")),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// 🔥 QR CODE مع Animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: child,
                );
              },
              child: active
                  ? Container(
                      key: ValueKey(code),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: code,
                        version: QrVersions.auto,
                        size: 140,
                      ),
                    )
                  : const SizedBox(),
            ),

            const SizedBox(height: 12),

            /// 📅 Dates
            Row(
              children: [
                const Icon(Icons.event, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    createdAt == null
                        ? '—'
                        : "${t.createdAt}: ${createdAt.toString().substring(0, 16)}",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    expiresAt == null
                        ? t.noExpiry
                        : "${t.expiresAt}: ${expiresAt.toString().substring(0, 16)}",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// 🎛️ Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      active
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    label: Text(active ? t.disable : t.enable),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: active
                          ? Colors.orange.shade300
                          : Colors.green,
                    ),
                    onPressed: () => _toggleActive(ref, active),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: Text(t.delete),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300,
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
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 64, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              t.noSecretaryCodes,
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

class CodeQrDialog extends StatelessWidget {
  final String code;
  final DateTime? expiresAt;

  const CodeQrDialog({super.key, required this.code, this.expiresAt});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final safeCode = code.trim();
    final size = MediaQuery.of(context).size;
    final double qrSize = (size.shortestSide * 0.6).clamp(140.0, 260.0);

    final expireText = expiresAt == null
        ? t.noExpiry
        : "${t.expiresAt}: ${expiresAt.toString().substring(0, 16)}";

    final validation = QrValidator.validate(
      data: safeCode,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    final valid = validation.status == QrValidationStatus.valid;

    return AlertDialog(
      title: Text(t.secretaryQrCode),
      content: SingleChildScrollView(
        child: Column(
          children: [
            if (valid)
              Container(
                width: qrSize,
                height: qrSize,
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: CustomPaint(
                  size: Size.square(qrSize - 20),
                  painter: QrPainter.withQr(
                    qr: validation.qrCode!,
                    gapless: true,
                    color: Colors.black,
                    emptyColor: Colors.white,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(t.qrGenerationFailed, textAlign: TextAlign.center),
              ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    safeCode,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.copyCode,
                  icon: const Icon(Icons.copy_all_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: safeCode));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${t.copied}: $safeCode")),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(expireText)),
              ],
            ),
          ],
        ),
      ),

      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.done),
        ),
      ],
    );
  }
}
