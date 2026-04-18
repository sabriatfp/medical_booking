// lib/admin/ui/admin_subscriptions_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

enum SubFilter { all, active, inactive, expiringSoon }

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  final _searchCtrl = TextEditingController();
  SubFilter _filter = SubFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _doctorsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .orderBy('email')
        .snapshots();
  }

  bool _isActive(Map<String, dynamic> data) {
    final active = (data['subscriptionActive'] ?? false) == true;
    if (!active) return false;

    final ts = data['subscriptionEnd'];
    if (ts == null || ts is! Timestamp) return active;

    return ts.toDate().isAfter(DateTime.now());
  }

  int? _daysLeft(Map<String, dynamic> data) {
    final ts = data['subscriptionEnd'];
    if (ts == null || ts is! Timestamp) return null;

    final end = ts.toDate();
    return end.difference(DateTime.now()).inDays;
  }

  bool _isExpiringSoon(Map<String, dynamic> data) {
    if (!_isActive(data)) return false;

    final days = _daysLeft(data);
    if (days == null) return false;
    return days <= 7;
  }

  bool _passesFilter(Map<String, dynamic> data) {
    switch (_filter) {
      case SubFilter.all:
        return true;
      case SubFilter.active:
        return _isActive(data);
      case SubFilter.inactive:
        return !_isActive(data);
      case SubFilter.expiringSoon:
        return _isExpiringSoon(data);
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final name = (data['name'] ?? '').toString().toLowerCase();
    final email = (data['email'] ?? '').toString().toLowerCase();

    return name.contains(q) || email.contains(q);
  }

  String _fmtDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  // --------------------------------------
  // عمليات الاشتراك
  // --------------------------------------
  Future<void> _updateDoctorSubscription({
    required String doctorUid,
    required String doctorId,
    required bool active,
    DateTime? end,
    String? plan,
  }) async {
    final db = FirebaseFirestore.instance;
    final usersRef = db.collection('users').doc(doctorUid);
    final subsRef = db.collection('doctor_subscriptions').doc(doctorId);

    await db.runTransaction((tx) async {
      tx.set(usersRef, {
        'subscriptionActive': active,
        'subscriptionEnd': end == null ? null : Timestamp.fromDate(end.toUtc()),
        if (plan != null) 'subscriptionPlan': plan,
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(subsRef, {
        'active': active,
        'end': end == null ? null : Timestamp.fromDate(end.toUtc()),
        if (plan != null) 'plan': plan,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _activateFor(
    String userId,
    Map<String, dynamic> userData, {
    required Duration duration,
    required AppLocalizations t,
    String? plan,
  }) async {
    final doctorId = (userData['doctorId'] ?? '').toString();
    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.noDoctorId)));
      return;
    }

    final now = DateTime.now().toUtc();
    final end = now.add(duration);

    await _updateDoctorSubscription(
      doctorUid: userId,
      doctorId: doctorId,
      active: true,
      end: end,
      plan: plan ?? 'manual',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${t.activatedUntil} ${_fmtDate(end.toLocal())}")),
    );
  }

  Future<void> _activateCustomDialog(
    String userId,
    Map<String, dynamic> userData,
    AppLocalizations t,
  ) async {
    final controller = TextEditingController(text: '30');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Duration>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.customActivation),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: t.daysCount),
            validator: (v) {
              final value = int.tryParse(v ?? '');
              if (value == null || value <= 0) return t.invalidDays;
              if (value > 3650) return t.daysTooLarge;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final days = int.parse(controller.text);
                Navigator.pop(ctx, Duration(days: days));
              }
            },
            child: Text(t.activate),
          ),
        ],
      ),
    );

    if (result != null) {
      await _activateFor(
        userId,
        userData,
        duration: result,
        plan: 'custom',
        t: t,
      );
    }
  }

  Future<void> _deactivate(
    String userId,
    Map<String, dynamic> userData,
    AppLocalizations t,
  ) async {
    final doctorId = (userData['doctorId'] ?? '').toString().trim();

    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.noDoctorId)));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deactivateSubscription),
        content: Text(t.confirmDeactivate),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.deactivate),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _updateDoctorSubscription(
      doctorUid: userId,
      doctorId: doctorId,
      active: false,
      end: null,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.deactivated)));
  }

  PopupMenuButton<int> _actionsMenu(
    String userId,
    Map<String, dynamic> data,
    AppLocalizations t,
  ) {
    final isActiveNow = _isActive(data);
    final hasDoctorId = (data['doctorId'] ?? '').toString().trim().isNotEmpty;

    return PopupMenuButton<int>(
      onSelected: (value) async {
        try {
          if (value == 7) {
            await _activateFor(
              userId,
              data,
              duration: const Duration(days: 7),
              plan: '7d',
              t: t,
            );
          } else if (value == 30) {
            await _activateFor(
              userId,
              data,
              duration: const Duration(days: 30),
              plan: '30d',
              t: t,
            );
          } else if (value == 90) {
            await _activateFor(
              userId,
              data,
              duration: const Duration(days: 90),
              plan: '90d',
              t: t,
            );
          } else if (value == 0) {
            await _activateCustomDialog(userId, data, t);
          } else if (value == -1) {
            await _deactivate(userId, data, t);
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("${t.actionFailed} $e")));
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 7, enabled: hasDoctorId, child: Text(t.activate7)),
        PopupMenuItem(
          value: 30,
          enabled: hasDoctorId,
          child: Text(t.activate30),
        ),
        PopupMenuItem(
          value: 90,
          enabled: hasDoctorId,
          child: Text(t.activate90),
        ),
        PopupMenuItem(
          value: 0,
          enabled: hasDoctorId,
          child: Text(t.customActivation),
        ),
        PopupMenuItem(
          value: -1,
          enabled: hasDoctorId && isActiveNow,
          child: Text(t.deactivateSubscription),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminSubscriptions)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: t.searchByNameEmail,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: t.refresh,
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DropdownButtonFormField<SubFilter>(
              value: _filter,
              decoration: InputDecoration(
                labelText: t.filter,
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.filter_list),
              ),
              items: [
                DropdownMenuItem(value: SubFilter.all, child: Text(t.all)),
                DropdownMenuItem(
                  value: SubFilter.active,
                  child: Text(t.active),
                ),
                DropdownMenuItem(
                  value: SubFilter.inactive,
                  child: Text(t.inactive),
                ),
                DropdownMenuItem(
                  value: SubFilter.expiringSoon,
                  child: Text(t.expiringSoon),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _filter = v);
                }
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _doctorsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(
                    child: Text("${t.errorLoading}: ${snap.error}"),
                  );
                }

                final docs = (snap.data?.docs ?? [])
                    .where((d) => _matchesSearch(d.data()))
                    .where((d) => _passesFilter(d.data()))
                    .toList();

                if (docs.isEmpty) {
                  return Center(child: Text(t.noResults));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final userId = doc.id;
                    print(
                      'ADMIN SUB → userId=$userId, doctorId=${data['doctorId']}, active=${_isActive(data)}',
                    );

                    final name = (data['name'] ?? t.noName).toString();
                    final email = (data['email'] ?? '').toString();
                    final doctorId = (data['doctorId'] ?? '').toString();

                    final active = _isActive(data);
                    final daysLeft = _daysLeft(data);

                    DateTime? endDate;
                    final ts = data['subscriptionEnd'];
                    if (ts is Timestamp) {
                      endDate = ts.toDate();
                    }

                    String status = "";
                    Color color;

                    if (active) {
                      status = daysLeft != null
                          ? "${t.active} — ${_fmtDate(endDate!)} (${t.remainingDays(daysLeft)})"
                          : t.active;
                      color = Colors.green;
                    } else {
                      status =
                          endDate != null && endDate.isBefore(DateTime.now())
                          ? t.expired
                          : t.inactive;
                      color = Colors.red;
                    }

                    if (_isExpiringSoon(data)) {
                      status += " • ${t.expiringSoon}";
                      color = Colors.orange;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: const Icon(Icons.person, color: Colors.teal),
                      ),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (email.isNotEmpty)
                            Text(email, textDirection: TextDirection.ltr),
                          if (doctorId.isNotEmpty)
                            Text(
                              "doctorId: $doctorId",
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: _actionsMenu(userId, data, t),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
