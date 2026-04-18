// lib/services/doctor_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DoctorService {
  static Future<void> normalizeRollingWeeks({
    required String doctorId,
    required Map<String, Map<String, dynamic>> weeklyTemplate,
    required Set<String> exceptionalDaysOff,
    required int slotDuration,
  }) async {
    if (slotDuration <= 0) return; // ✅ أضف هذا

    final docRef = FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId);

    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    List weeks = List.from(data['weeks'] ?? []);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 1️⃣ حذف الأسابيع المنتهية
    weeks.removeWhere((w) {
      final start = DateTime.parse(w['startDate']);
      final end = start.add(const Duration(days: 6));
      return end.isBefore(todayDate.subtract(const Duration(days: 1)));
    });

    // 2️⃣ توليد الأيام (نفس منطقك)
    List<Map<String, dynamic>> generateWeekDays(DateTime startDate) {
      final List<Map<String, dynamic>> output = [];

      for (int i = 0; i < 7; i++) {
        final d = startDate.add(Duration(days: i));
        final dateStr = DateFormat("yyyy-MM-dd").format(d);
        final dayName = [
          "الإثنين",
          "الثلاثاء",
          "الأربعاء",
          "الخميس",
          "الجمعة",
          "السبت",
          "الأحد",
        ][d.weekday - 1];

        final tmpl = weeklyTemplate[dayName];

        if (tmpl == null) {
          output.add({
            "date": dateStr,
            "available": false,
            "start": null,
            "end": null,
            "slots": [],
            "full": true,
          });
          continue;
        }

        final isDayOff = exceptionalDaysOff.contains(dateStr);
        final available = tmpl["available"] == true && !isDayOff;

        List<String> slots = [];
        if (available) {
          int startMin =
              int.parse(tmpl["start"].split(":")[0]) * 60 +
              int.parse(tmpl["start"].split(":")[1]);
          int endMin =
              int.parse(tmpl["end"].split(":")[0]) * 60 +
              int.parse(tmpl["end"].split(":")[1]);

          while (startMin + slotDuration <= endMin) {
            final h = (startMin ~/ 60).toString().padLeft(2, '0');
            final m = (startMin % 60).toString().padLeft(2, '0');
            slots.add("$h:$m");
            startMin += slotDuration;
          }
        }

        output.add({
          "date": dateStr,
          "available": available,
          "start": tmpl["start"],
          "end": tmpl["end"],
          "slots": slots,
          "full": false,
        });
      }

      return output;
    }

    // 3️⃣ إضافة أسابيع جديدة حتى يصبح العدد 3
    // 3️⃣ إضافة أسابيع جديدة حتى يصبح العدد 3
    while (weeks.length < 3) {
      DateTime newStart;

      if (weeks.isEmpty) {
        // ✅ أبقِ الأسبوع الحالي (تحسين UX)
        newStart = startOfCurrentWeek(todayDate);
      } else {
        final lastStart = DateTime.parse(weeks.last['startDate']);
        newStart = lastStart.add(const Duration(days: 7));
      }

      weeks.add({
        "startDate": newStart.toIso8601String(),
        "days": generateWeekDays(newStart),
      });
    }

    // 4️⃣ حفظ فقط إذا حصل تغيير
    await docRef.set({"weeks": weeks}, SetOptions(merge: true));
  }

  static DateTime startOfCurrentWeek(DateTime today) {
    // الاثنين = 1
    return DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - DateTime.monday));
  }

  DoctorService();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  /// عدّل اسم الحقل الزمني للمواعيد إذا كان مختلفًا في سكيمتك:
  /// - 'dateTime' (الذي ظهر في واجهتك)
  /// - أو 'scheduledAt' إن كنت تستخدمه في بعض الأماكن.
  static const String kApptTimeField =
      'dateTime'; // غيّره إلى 'scheduledAt' إذا لزم

  // ======================
  // Helpers
  // ======================

  String? _uid() => FirebaseAuth.instance.currentUser?.uid;

  Future<String?> _role() async {
    final uid = _uid();
    if (uid == null) return null;
    try {
      final snap = await _fs.collection('users').doc(uid).get();
      return (snap.data()?['role'] ?? '').toString();
    } catch (e, st) {
      if (kDebugMode) debugPrint('role() read error: $e\n$st');
      return null;
    }
  }

  /// يستنتج doctorId للمستخدم الحالي:
  /// 1) من users/{uid}.doctorId (المصدر الأساسي)
  /// 2) (احتياطي) استعلام doctors.where('ownerUid'==uid) إن كان الدور Doctor
  Future<String?> getDoctorId() async {
    final uid = _uid();
    if (uid == null) return null;

    // (1) users/{uid}.doctorId
    try {
      final userDoc = await _fs.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data != null &&
          data['doctorId'] is String &&
          (data['doctorId'] as String).isNotEmpty) {
        return data['doctorId'] as String;
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('getDoctorId() users read error: $e\n$st');
      // نكمل للمسار الاحتياطي فقط إن كان الدور Doctor
    }

    // (2) احتياطي: إن كان الدور Doctor
    final role = await _role();
    if (role != 'doctor') return null;

    try {
      final q = await _fs
          .collection('doctors')
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .get(); // يتطلب allow list للأدمن/المالك (مفعل في القواعد)

      if (q.docs.isNotEmpty) {
        return q.docs.first.id;
      }
    } on FirebaseException catch (e, st) {
      // لو permission-denied هنا، القواعد لا تسمح بهذا الاستعلام لحسابك
      if (kDebugMode) {
        debugPrint(
          'getDoctorId() doctors query error: ${e.code} ${e.message}\n$st',
        );
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) debugPrint('getDoctorId() unknown error: $e\n$st');
      return null;
    }

    return null;
  }

  // ======================
  // Appointments
  // ======================

  /// Stream للمواعيد لطبيب معيّن مع فلترة حالة اختيارية
  /// ملاحظة: القواعد تسمح للطبيب (المرتبط بـ users/{uid}.doctorId) بقراءة appointments
  /// التي doctorId فيها يساوي معرّفه. السكرتير (جلسة فعالة) والأدمن كذلك لديهم صلاحيات.
  Stream<QuerySnapshot<Map<String, dynamic>>> appointmentsStream(
    String doctorId,
    String? status,
  ) {
    Query<Map<String, dynamic>> q = _fs
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId);

    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }

    // ⚠️ إذا كان اسم الحقل الزمني لديك 'scheduledAt' عدّل الثابت kApptTimeField أعلاه.
    // ⚠️ إن ظهر لك "FAILED_PRECONDITION: The query requires an index" أنشئ الفهرس من الرابط المطبوع في الكونسول.
    return q.orderBy(kApptTimeField, descending: false).snapshots();
  }

  /// تحديث حالة الموعد وفق القواعد
  /// الحقول المسموحة: status, updatedAt, confirmedAt, cancelledAt, checkedInAt, noShowAt, statusNote, updatedBy
  /// الحالات المسموحة: pending, confirmed, checked_in, no_show, canceled/cancelled
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status, {
    String? statusNote,
  }) async {
    final uid = _uid();
    final now = FieldValue.serverTimestamp();

    final Map<String, dynamic> data = <String, dynamic>{
      'status': status,
      'updatedAt': now,
      'updatedBy': uid,
    };

    if (statusNote != null && statusNote.trim().isNotEmpty) {
      data['statusNote'] = statusNote.trim();
    }

    switch (status) {
      case 'confirmed':
        data['confirmedAt'] = now;
        break;
      case 'checked_in':
        data['checkedInAt'] = now;
        break;
      case 'no_show':
        data['noShowAt'] = now;
        break;
      case 'canceled':
      case 'cancelled':
        // اخترنا الإبقاء على الحقل 'cancelledAt' كما في القواعد
        data['cancelledAt'] = now;
        break;
    }

    try {
      await _fs.collection('appointments').doc(appointmentId).update(data);
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'updateAppointmentStatus error: ${e.code} ${e.message}\n$st',
        );
      }
      rethrow; // دع المستدعي يتعامل مع الرسالة (SnackBar) كما تفعل في الواجهة
    }
  }

  // ======================
  // Secretary Codes
  // ======================

  /// إنشاء كود سكرتير جديد داخل:
  ///   - المسار الخاص:  doctors/{doctorId}/secretary_codes/{autoId}
  ///   - (اختياري) المسار العام: secretary_codes_public/{code}
  ///
  /// القواعد تشترط:
  ///   - وجود 'doctorId' في البيانات
  ///   - createdBy == uid
  ///   - قبول serverTimestamp في createdAt/updatedAt/expiresAt
  ///
  /// ترجع: معرف وثيقة الكود في المسار الخاص (أو null عند الفشل)
  Future<String?> createSecretaryCode({
    required String doctorId,
    required String code,
    DateTime? expiresAt,
    bool alsoPublishPublic = true,
  }) async {
    final uid = _uid();
    if (uid == null) return null;

    final batch = _fs.batch();
    final now = FieldValue.serverTimestamp();

    // بيانات المسار الخاص
    final privateCol = _fs
        .collection('doctors')
        .doc(doctorId)
        .collection('secretary_codes');
    final privateDocRef = privateCol.doc(); // autoId

    final privateData = <String, dynamic>{
      'code': code,
      'doctorId': doctorId, // ⬅️ مطلوب في القواعد الجديدة
      'active': true,
      'createdAt': now,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'createdBy': uid,
      'used': false,
      'usedAt': null,
      'usedByUid': null,
    };

    batch.set(privateDocRef, privateData);

    // بيانات المسار العام (اختياري)
    if (alsoPublishPublic) {
      final publicDocRef = _fs.collection('secretary_codes_public').doc(code);
      final publicData = <String, dynamic>{
        'code': code,
        'doctorId': doctorId,
        'active': true,
        'createdAt': now,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      };
      batch.set(publicDocRef, publicData);
    }

    try {
      await batch.commit();
      return privateDocRef.id;
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'createSecretaryCode FIREBASE ERROR: ${e.code} ${e.message}\n$st',
        );
      }
      return null;
    } catch (e, st) {
      if (kDebugMode) debugPrint('createSecretaryCode unknown error: $e\n$st');
      return null;
    }
  }

  /// Stream لأكواد السكرتير (الأحدث أولًا) من المسار الخاص
  Stream<QuerySnapshot<Map<String, dynamic>>> secretaryCodesStream(
    String doctorId,
  ) {
    return _fs
        .collection('doctors')
        .doc(doctorId)
        .collection('secretary_codes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// استهلاك/إبطال كود سكرتير (المسار الخاص)
  /// - use: وضع used=true, usedAt, usedByUid
  /// - deactivate: active=false, updatedAt
  Future<bool> consumeOrDeactivateSecretaryCode({
    required String doctorId,
    required String codeId,
    bool use = true,
    String? usedByUid,
    bool deactivate = false,
  }) async {
    final now = FieldValue.serverTimestamp();
    final updates = <String, dynamic>{};

    if (use) {
      updates['used'] = true;
      updates['usedAt'] = now;
      updates['usedByUid'] = usedByUid;
    }
    if (deactivate) {
      updates['active'] = false;
      updates['updatedAt'] = now;
    }

    try {
      await _fs
          .collection('doctors')
          .doc(doctorId)
          .collection('secretary_codes')
          .doc(codeId)
          .update(updates);
      return true;
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'consumeOrDeactivateSecretaryCode error: ${e.code} ${e.message}\n$st',
        );
      }
      return false;
    }
  }
}
