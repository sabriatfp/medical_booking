// lib/admin/ui/admin_subscriptions_screen.dart
import 'package:firebase_auth/firebase_auth.dart';

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
  Map<String, dynamic>? _navArgs;
  final _searchCtrl = TextEditingController();
  SubFilter _filter = SubFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_navArgs != null) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _navArgs = args;

      final doctorUid = args['doctorUid'];

      // ✅ مهم: تنفيذ بعد build
      Future.microtask(() async {
        final t = AppLocalizations.of(context)!;

        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(doctorUid)
              .get();

          final data = userDoc.data();
          if (data == null) return;

          // ✅ افتح dialog مباشرة
        } catch (e) {
          debugPrint("Auto dialog error: $e");
        }
      });
    }
  }

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

    return ts.toDate().isAfter(DateTime.now().toUtc());
  }

  int? _daysLeft(Map<String, dynamic> data) {
    final ts = data['subscriptionEnd'];
    if (ts == null || ts is! Timestamp) return null;

    final end = ts.toDate();
    return end.toUtc().difference(DateTime.now().toUtc()).inDays;
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
    required bool active,
    DateTime? end,
    String? plan,
  }) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(doctorUid);

    final endTimestamp = end == null ? null : Timestamp.fromDate(end.toUtc());
    final now = DateTime.now().toUtc();
    // ✅ 1. تحديث users (كما هو)
    await userRef.update({
      'subscriptionActive': active,
      'subscriptionEnd': active ? endTimestamp : null,
      if (plan != null) 'subscriptionType': plan,
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      'subscriptionUpdatedBy':
          FirebaseAuth.instance.currentUser?.uid ?? 'admin',
    });

    // ✅ 2. NEW: Sync مع doctors collection
    try {
      final userSnap = await userRef.get();
      final doctorId = userSnap.data()?['doctorId'];

      if (doctorId != null && doctorId.toString().isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .update({
              'subscriptionActive': active,
              'subscriptionEnd': active ? endTimestamp : null,

              'gracePeriodEnd': active
                  ? null
                  : Timestamp.fromDate(now.add(const Duration(days: 10))),

              'isVisibleInSearch': true,
            });
      }
    } catch (e) {
      debugPrint("Doctor sync failed: $e");
    }
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
      active: true,
      end: end,
      plan: plan ?? 'manual',
    );

    /// ✅ ✅ ✅ هنا الحل
    final requestId = _navArgs?['requestId'];
    if (requestId != null) {
      await FirebaseFirestore.instance
          .collection('subscription_requests')
          .doc(requestId)
          .update({
            'status': 'processed',
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
          });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${t.activatedUntil} ${_fmtDate(end.toLocal())}")),
    );

    if (_navArgs?['requestId'] != null && mounted) {
      Navigator.pop(context);
    }
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

  Widget _quickBtn(String label, Color color, Future<void> Function() onTap) {
    return ElevatedButton(
      onPressed: () async {
        await onTap(); // ✅ الحل
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(40, 30),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  Future<bool> _confirmAction(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    return result ?? false;
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
      active: false,
      end: null,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.deactivated)));
  }

  Widget _actionsMenu(
    BuildContext tileContext,
    String userId,
    Map<String, dynamic> data,
    AppLocalizations t,
  ) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () async {
        final RenderBox box = tileContext.findRenderObject() as RenderBox;
        final Offset position = box.localToGlobal(Offset.zero);

        final selected = await showMenu<int>(
          context: context,
          position: RelativeRect.fromLTRB(
            position.dx,
            position.dy,
            position.dx + box.size.width,
            position.dy + box.size.height,
          ),
          items: [
            PopupMenuItem(value: 7, child: Text(t.activate7)),
            PopupMenuItem(value: 30, child: Text(t.activate30)),
            PopupMenuItem(value: 90, child: Text(t.activate90)),
            PopupMenuItem(value: 0, child: Text(t.customActivation)),
            const PopupMenuDivider(),
            PopupMenuItem(value: -1, child: Text(t.deactivateSubscription)),
          ],
        );

        if (selected == null) return;

        try {
          if (selected == 7) {
            await _activateFor(
              userId,
              data,
              duration: const Duration(days: 7),
              t: t,
              plan: '7d',
            );
          } else if (selected == 30) {
            await _activateFor(
              userId,
              data,
              duration: const Duration(days: 30),
              t: t,
              plan: '30d',
            );
          } else if (selected == 90) {
            await _activateFor(
              userId,
              data,
              duration: const Duration(days: 90),
              t: t,
              plan: '90d',
            );
          } else if (selected == 0) {
            await _activateCustomDialog(userId, data, t);
          } else if (selected == -1) {
            await _deactivate(userId, data, t);
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("${t.actionFailed}: $e")));
        }
      },
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

                final allDocs = (snap.data?.docs ?? [])
                    .where((d) => _matchesSearch(d.data()))
                    .where((d) => _passesFilter(d.data()))
                    .toList();

                /// ✅ إذا دخلنا من request → نعرض طبيب واحد فقط
                List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

                if (_navArgs != null && _navArgs?['doctorUid'] != null) {
                  final targetId = _navArgs!['doctorUid'];

                  docs = allDocs.where((d) => d.id == targetId).toList();
                } else {
                  docs = allDocs;
                }

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
                    debugPrint(
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

                    final isFromRequest = _navArgs?['doctorUid'] == userId;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),

                        /// ✅ Border حسب الحالة
                        border: Border.all(
                          color: isFromRequest
                              ? Colors.orange
                              : _isExpiringSoon(data)
                              ? Colors.orange
                              : active
                              ? Colors.green
                              : Colors.red,
                          width: 1.5,
                        ),

                        /// ✅ Shadow
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// ✅ HEADER
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.teal.shade100,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            /// ✅ Email
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: const TextStyle(color: Colors.grey),
                              ),

                            /// ✅ Status
                            const SizedBox(height: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// ✅ ACTION BAR
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _quickBtn(
                                  "7d",
                                  const Color.fromARGB(255, 122, 190, 247),
                                  () async {
                                    final ok = await _confirmAction(
                                      "Activate 7 days?",
                                    );
                                    if (!ok) return;

                                    await _activateFor(
                                      userId,
                                      data,
                                      duration: const Duration(days: 7),
                                      t: t,
                                      plan: '7d',
                                    );
                                  },
                                ),

                                _quickBtn(
                                  "30d",
                                  const Color.fromARGB(255, 135, 231, 138),
                                  () async {
                                    final ok = await _confirmAction(
                                      "Activate 30 days?",
                                    );
                                    if (!ok) return;

                                    await _activateFor(
                                      userId,
                                      data,
                                      duration: const Duration(days: 30),
                                      t: t,
                                      plan: '30d',
                                    );
                                  },
                                ),

                                _quickBtn(
                                  "90d",
                                  const Color.fromARGB(255, 241, 192, 117),
                                  () async {
                                    final ok = await _confirmAction(
                                      "Activate 90 days?",
                                    );
                                    if (!ok) return;

                                    await _activateFor(
                                      userId,
                                      data,
                                      duration: const Duration(days: 90),
                                      t: t,
                                      plan: '90d',
                                    );
                                  },
                                ),

                                /// ✅ Custom
                                OutlinedButton(
                                  onPressed: () {
                                    _activateCustomDialog(userId, data, t);
                                  },
                                  child: const Text("+"),
                                ),

                                /// ✅ Deactivate
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final ok = await _confirmAction(
                                        "Deactivate subscription?",
                                      );
                                      if (!ok) return;

                                      _deactivate(userId, data, t);
                                    },
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
          ),
        ],
      ),
    );
  }
}
