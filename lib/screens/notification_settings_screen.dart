import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import 'package:medical_booking/services/push_service.dart';

enum UserRole { doctor, patient }

class NotificationSettingsScreen extends StatefulWidget {
  final UserRole role;
  final String userId;

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
    final t = AppLocalizations.of(context)!;

    try {
      final snap = await _docRef.get();
      final data = snap.data() ?? {};

      setState(() {
        _allowPush = (data['allowPush'] as bool?) ?? true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack("${t.loadSettingsFailed}: $e");
    }
  }

  Future<void> _toggleAllow(bool value) async {
    final t = AppLocalizations.of(context)!;

    setState(() {
      _allowPush = value;
      _saving = true;
    });

    try {
      await _docRef.set({'allowPush': value}, SetOptions(merge: true));

      if (value) {
        await PushService.instance.showLocalNotification(
          title: t.notificationsEnabled,
          body: t.notificationsEnabledMessage,
        );
      }
    } catch (e) {
      setState(() => _allowPush = !value);
      _snack("${t.saveFailed}: $e");
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _sendTestLocal() async {
    final t = AppLocalizations.of(context)!;

    if (!_allowPush) {
      _snack(t.notificationsDisabled);
      return;
    }

    await PushService.instance.showLocalNotification(
      title: t.testNotificationTitle,
      body: t.testNotificationMessage,
      data: {
        'route': '/home',
        'from': 'notification_settings',
        'role': widget.role.name,
      },
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notificationSettings),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
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
            title: Text(t.allowNotifications),
            subtitle: Text(t.allowNotificationsDescription),
            value: _allowPush,
            onChanged: _toggleAllow,
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _sendTestLocal,
            icon: const Icon(Icons.send),
            label: Text(t.sendTestNotification),
          ),

          const SizedBox(height: 20),

          Text(
            t.fcmDisabledNote,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
