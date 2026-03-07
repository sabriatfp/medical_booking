import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyResult {
  final bool ok;
  final String? doctorId;

  /// معرّف الوثيقة (قد يكون مساويًا للكود النصّي إذا استُخدم كـ docId)
  final String? codeId;

  /// الكود النصّي داخل الوثيقة (إن وُجد)، نرجّعه للتكامل
  final String? code;

  /// تاريخ الانتهاء (إن وُجد في الوثيقة العامة)
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

  /// يتحقق من الكود في:
  /// 1) secretary_codes_public/{code}  (docId == الكود) ← مفضّل
  /// 2) secretary_codes/{code}        (fallback)        ← يتطلب Rule: allow get
  ///
  /// يعيد: doctorId, codeId, code, expiresAt (إن وجدت)
  Future<VerifyResult> verify(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      return const VerifyResult(ok: false, reason: 'أدخل الكود');
    }

    try {
      // --- المسار 1: secretary_codes_public/{code}
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
          return const VerifyResult(ok: false, reason: 'الكود معطّل');
        }
        if (expired) {
          return const VerifyResult(ok: false, reason: 'الكود منتهي الصلاحية');
        }

        final String? doctorId = data['doctorId'] as String?;
        if (doctorId == null || doctorId.isEmpty) {
          return const VerifyResult(
            ok: false,
            reason: 'بيانات الكود غير مكتملة',
          );
        }

        // نعيد أيضًا codeId (docId) و code (إن وُجد بالحقل)
        final String? codeField = data['code'] as String?;
        return VerifyResult(
          ok: true,
          doctorId: doctorId,
          codeId: pubDoc.id,
          code: codeField ?? pubDoc.id,
          expiresAt: expiresAt,
        );
      }

      // --- المسار 2 (fallback): secretary_codes/{code}
      // لقطة الشاشة عندك تُظهر كولكشن جذري باسم "secretary_codes"
      // نستخدم get بالمعرّف مباشرة (ليس query) ← يتطلب Rule: allow get فقط
      final rootDoc = await _db.collection('secretary_codes').doc(code).get();
      if (!rootDoc.exists) {
        return const VerifyResult(ok: false, reason: 'الكود غير موجود');
      }

      final rdata = rootDoc.data()!;
      final bool rActive = (rdata['active'] == true);
      final Timestamp? rExpiresTs = rdata['expiresAt'] as Timestamp?;
      final DateTime? rExpiresAt = rExpiresTs?.toDate();
      final bool rExpired =
          rExpiresAt != null && rExpiresAt.isBefore(DateTime.now());
      if (!rActive) {
        return const VerifyResult(ok: false, reason: 'الكود غير مفعّل');
      }
      if (rExpired) {
        return const VerifyResult(ok: false, reason: 'الكود منتهي الصلاحية');
      }

      final String? rDoctorId = rdata['doctorId'] as String?;
      if (rDoctorId == null || rDoctorId.isEmpty) {
        return const VerifyResult(ok: false, reason: 'بيانات الكود غير مكتملة');
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
      return VerifyResult(ok: false, reason: 'تعذّر الاتصال: ${e.code}');
    } catch (_) {
      return const VerifyResult(ok: false, reason: 'خطأ غير متوقع');
    }
  }
}
