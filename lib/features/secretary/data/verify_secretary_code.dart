// lib/features/secretary/data/verify_secretary_code.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

class VerifyResult {
  final bool ok;
  final String? doctorId;
  final String? codeId;
  final String? code;
  final DateTime? expiresAt;
  final String? reason;

  const VerifyResult({
    required this.ok,
    this.doctorId,
    this.codeId,
    this.code,
    this.expiresAt,
    this.reason,
  });

  VerifyResult copyWith({
    bool? ok,
    String? doctorId,
    String? codeId,
    String? code,
    DateTime? expiresAt,
    String? reason,
  }) {
    return VerifyResult(
      ok: ok ?? this.ok,
      doctorId: doctorId ?? this.doctorId,
      codeId: codeId ?? this.codeId,
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      reason: reason ?? this.reason,
    );
  }
}

class SecretaryCodeVerifier {
  final FirebaseFirestore _db;
  SecretaryCodeVerifier([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  /// التحقق من كود السكرتير
  /// يعتمد على:
  /// 1) secretary_codes_public/{code}
  /// 2) secretary_codes/{code} (fallback)
  Future<VerifyResult> verify(String rawCode, BuildContext context) async {
    final t = AppLocalizations.of(context)!;

    final code = rawCode.trim();
    if (code.isEmpty) {
      return VerifyResult(ok: false, reason: t.enterCode);
    }

    try {
      // ----------------------------
      // ✅ المسار 1: المجموعة العامة
      // ----------------------------
      final pubDoc = await _db
          .collection('secretary_codes_public')
          .doc(code)
          .get();

      if (pubDoc.exists) {
        final data = pubDoc.data()!;
        final bool active = (data['active'] == true);

        final Timestamp? expiresTs = data['expiresAt'] as Timestamp?;
        final DateTime? expiresAt = expiresTs?.toDate();

        final bool expired =
            expiresAt != null && expiresAt.isBefore(DateTime.now());

        if (!active) {
          return VerifyResult(ok: false, reason: t.codeInactive);
        }
        if (expired) {
          return VerifyResult(ok: false, reason: t.codeExpired);
        }

        final String? doctorId = data['doctorId'] as String?;
        if (doctorId == null || doctorId.isEmpty) {
          return VerifyResult(ok: false, reason: t.codeIncomplete);
        }

        final String? codeField = data['code'] as String?;

        return VerifyResult(
          ok: true,
          doctorId: doctorId,
          codeId: pubDoc.id,
          code: codeField ?? pubDoc.id,
          expiresAt: expiresAt,
        );
      }

      // ----------------------------
      // ✅ المسار 2: fallback
      // ----------------------------
      final rootDoc = await _db.collection('secretary_codes').doc(code).get();

      if (!rootDoc.exists) {
        return VerifyResult(ok: false, reason: t.codeNotFound);
      }

      final rdata = rootDoc.data()!;
      final bool rActive = (rdata['active'] == true);

      final Timestamp? rExpiresTs = rdata['expiresAt'] as Timestamp?;
      final DateTime? rExpiresAt = rExpiresTs?.toDate();

      final bool rExpired =
          rExpiresAt != null && rExpiresAt.isBefore(DateTime.now());

      if (!rActive) {
        return VerifyResult(ok: false, reason: t.codeInactive);
      }
      if (rExpired) {
        return VerifyResult(ok: false, reason: t.codeExpired);
      }

      final String? rDoctorId = rdata['doctorId'] as String?;
      if (rDoctorId == null || rDoctorId.isEmpty) {
        return VerifyResult(ok: false, reason: t.codeIncomplete);
      }

      final String? rCodeField = rdata['code'] as String?;

      return VerifyResult(
        ok: true,
        doctorId: rDoctorId,
        codeId: rootDoc.id,
        code: rCodeField ?? rootDoc.id,
        expiresAt: rExpiresAt,
      );
    } on FirebaseException catch (e) {
      return VerifyResult(ok: false, reason: "${t.connectionError}: ${e.code}");
    } catch (_) {
      return VerifyResult(ok: false, reason: t.unexpectedError);
    }
  }
}
