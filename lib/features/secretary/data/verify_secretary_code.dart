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
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return const VerifyResult(ok: false, reason: 'أدخل الكود');
    }

    try {
      final pubDoc = await _db
          .collection('secretary_codes_public')
          .doc(code)
          .get();

      if (!pubDoc.exists) {
        return const VerifyResult(ok: false, reason: 'الكود غير موجود');
      }

      final data = pubDoc.data()!;
      if (data['active'] != true) {
        return const VerifyResult(ok: false, reason: 'الكود معطّل');
      }

      final Timestamp? expiresTs = data['expiresAt'] as Timestamp?;
      if (expiresTs != null && expiresTs.toDate().isBefore(DateTime.now())) {
        return const VerifyResult(ok: false, reason: 'الكود منتهي الصلاحية');
      }

      final String? doctorId = data['doctorId'] as String?;
      if (doctorId == null || doctorId.isEmpty) {
        return const VerifyResult(ok: false, reason: 'بيانات الكود غير مكتملة');
      }

      return VerifyResult(
        ok: true,
        doctorId: doctorId,
        codeId: pubDoc.id,
        code: data['code'] as String? ?? pubDoc.id,
        expiresAt: expiresTs?.toDate(),
      );
    } on FirebaseException catch (e) {
      return VerifyResult(ok: false, reason: 'خطأ في الاتصال (${e.code})');
    } catch (_) {
      return const VerifyResult(
        ok: false,
        reason: 'خطأ غير متوقع أثناء التحقق',
      );
    }
  }
}
