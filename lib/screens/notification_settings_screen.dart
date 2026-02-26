// lib/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';

// ✅ Firestore فقط (بدون Messaging حالياً)
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ إشعارات محلية فقط الآن للتجريب
import 'package:medical_booking/services/push_service.dart';

// إن لم يكن لديك تعريف UserRole بمكان آخر، استخدم هذا
enum UserRole { doctor, patient }

class NotificationSettingsScreen extends StatefulWidget {
  final UserRole role;
  final String userId; // doctorId أو patientId (وليس uid)

  const NotificationSettingsScreen({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final DocumentReference<Map<String, dynamic>> _docRef;

  bool _loading = true;
  bool _saving = false;

  /// يُحفظ في Firestore فقط الآن
  bool _allowPush = true;

  @override
  void initState() {
    super.initState();
    final collection = widget.role == UserRole.doctor ? 'doctors' : 'patients';
    _docRef = FirebaseFirestore.instance
        .collection(collection)
        .doc(widget.userId);
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await _docRef.get();
      final data = snap.data() ?? {};
      setState(() {
        _allowPush = (data['allowPush'] as bool?) ?? true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack('تعذر تحميل الإعدادات: $e');
    }
  }

  Future<void> _toggleAllow(bool value) async {
    setState(() {
      _allowPush = value;
      _saving = true;
    });
    try {
      // نحفظ allowPush فقط الآن
      await _docRef.set({'allowPush': value}, SetOptions(merge: true));

      // إشعار محلي لطيف عند التفعيل (بدون FCM حالياً)
      if (value) {
        await PushService.instance.showLocalNotification(
          title: 'تم تفعيل الإشعارات',
          body: 'سيتم إخطارك محليًا مؤقتًا (بدون FCM)',
        );
      }
    } catch (e) {
      // نرجّع القيمة بصريًا في حال فشل الحفظ
      setState(() => _allowPush = !value);
      _snack('تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTestLocal() async {
    if (!_allowPush) {
      _snack('الإشعارات معطلة. فعّلها أولاً');
      return;
    }
    await PushService.instance.showLocalNotification(
      title: 'إشعار تجريبي',
      body: 'هذا إشعار محلي للتجربة (بدون FCM حاليًا)',
      data: {
        'route': '/home',
        'from': 'notification_settings',
        'role': widget.role.name,
      },
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('السماح باستلام الإشعارات'),
            subtitle: const Text(
              'في حال الإيقاف، لن تصلك الإشعارات لهذا الحساب',
            ),
            value: _allowPush,
            onChanged: _toggleAllow,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('إشعار تجريبي (محلي)'),
                  onPressed: _sendTestLocal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ملاحظة: تم تعطيل FCM مؤقتًا. سيتم تفعيل تخزين توكنات الأجهزة وإرسال الإشعارات السحابية عند تفعيل Firebase Messaging لاحقًا.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
