// lib/screens/doctor/generate_codes_screen.dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

class GenerateCodesScreen extends StatefulWidget {
  final String doctorId;

  const GenerateCodesScreen({super.key, required this.doctorId});

  @override
  State<GenerateCodesScreen> createState() => _GenerateCodesScreenState();
}

class _GenerateCodesScreenState extends State<GenerateCodesScreen> {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _codesCol => _db
      .collection('doctors')
      .doc(widget.doctorId)
      .collection('secretary_codes');

  Stream<QuerySnapshot<Map<String, dynamic>>> _codesStream() {
    return _codesCol.orderBy('createdAt', descending: true).snapshots();
  }

  // =========================
  // توليد كود فريد
  // =========================
  Future<String> _generateUniqueCode({int length = 6}) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random.secure();

    String gen() =>
        List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();

    for (int i = 0; i < 8; i++) {
      final candidate = 'SEC-${gen()}';
      final exists = await _codesCol.doc(candidate).get();
      if (!exists.exists) return candidate;
    }
    throw Exception('Failed to generate unique code');
  }

  // =========================
  // إنشاء كود
  // =========================
  Future<void> _createCodeDialog() async {
    DateTime? pickedExpiry;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.createCode),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.optionalExpiryDate),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(AppLocalizations.of(context)!.chooseDate),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: now.add(const Duration(days: 7)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );

                    if (picked != null) {
                      setLocal(() {
                        pickedExpiry = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                        );
                      });
                    }
                  },
                ),
                if (pickedExpiry != null)
                  Text(
                    '${AppLocalizations.of(context)!.expiresOn}: '
                    '${DateFormat.yMd(Localizations.localeOf(context).languageCode).format(pickedExpiry!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!.create),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final code = await _generateUniqueCode();

    final privateRef = _codesCol.doc(code);
    final publicRef = _db.collection('secretary_codes_public').doc(code);

    final data = {
      'code': code,
      'doctorId': widget.doctorId,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      if (pickedExpiry != null) 'expiresAt': Timestamp.fromDate(pickedExpiry!),
    };

    final batch = _db.batch();
    batch.set(privateRef, data);
    batch.set(publicRef, data);

    await batch.commit();
  }

  // =========================
  // تفعيل / تعطيل
  // =========================
  Future<void> _toggleActive(String codeId, bool current) async {
    final batch = _db.batch();
    batch.update(_codesCol.doc(codeId), {'active': !current});
    batch.update(_db.collection('secretary_codes_public').doc(codeId), {
      'active': !current,
    });
    await batch.commit();
  }

  // =========================
  // حذف
  // =========================
  Future<void> _deleteCode(String codeId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text(AppLocalizations.of(context)!.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (ok == true) {
      final batch = _db.batch();
      batch.delete(_codesCol.doc(codeId));
      batch.delete(_db.collection('secretary_codes_public').doc(codeId));
      await batch.commit();
    }
  }

  // =========================
  // نسخ
  // =========================
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copied)),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMd(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.secretaryCodes),
        actions: [
          IconButton(onPressed: _createCodeDialog, icon: const Icon(Icons.add)),
        ],
      ),
      body: StreamBuilder(
        stream: _codesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text(t.noCodes));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final code = data['code'] as String;
              final active = data['active'] == true;
              final expires = data['expiresAt'] as Timestamp?;
              final qrSize = MediaQuery.of(context).size.width * 0.45;
              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      QrImageView(
                        data: code,
                        size: qrSize.clamp(200, 260),
                        backgroundColor: Colors.white,
                      ),

                      const SizedBox(height: 8),
                      SelectableText(
                        code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (expires != null)
                        Text(
                          '${t.expiresOn}: ${dateFmt.format(expires.toDate())}',
                          style: const TextStyle(fontSize: 12),
                        ),

                      /// ✅ عدد السكريتير
                      StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('secretary_sessions')
                            .where('codeId', isEqualTo: code)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox.shrink();
                          final count = snap.data!.docs
                              .map((d) => d['secretaryUid'])
                              .toSet()
                              .length;
                          return Text(
                            '${t.usedBy}: $count',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),

                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: t.copy,
                            onPressed: () => _copyCode(code),
                          ),
                          IconButton(
                            tooltip: active
                                ? AppLocalizations.of(context)!.inactive
                                : AppLocalizations.of(context)!.active,
                            icon: Icon(
                              active ? Icons.toggle_on : Icons.toggle_off,
                              size: 28,
                              color: active ? Colors.green : Colors.grey,
                            ),
                            onPressed: () async {
                              await _toggleActive(code, active);

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    active
                                        ? AppLocalizations.of(context)!.inactive
                                        : AppLocalizations.of(context)!.active,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Color.fromARGB(255, 3, 3, 3),
                            ),
                            tooltip: t.delete,
                            onPressed: () => _deleteCode(code),
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
