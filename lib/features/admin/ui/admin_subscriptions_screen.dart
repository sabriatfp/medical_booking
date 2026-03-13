import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  /// مصدر بيانات الأطباء: users حيث role = "doctor"
  Stream<QuerySnapshot<Map<String, dynamic>>> _doctorsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .orderBy(
          'email',
        ) // ترتيب ثابت؛ يمكنك تغييره إلى 'name' إذا كان موجودًا ومفهرسًا
        .snapshots();
  }

  /// حساب حالة الاشتراك
  bool _isActive(Map<String, dynamic> data) {
    final active = (data['subscriptionActive'] ?? false) == true;
    if (!active) return false;

    final ts = data['subscriptionEnd'];
    if (ts == null) return active; // لو لم تحدد تاريخ نهاية، نعتبره نشطًا
    if (ts is! Timestamp) return false;

    return ts.toDate().isAfter(DateTime.now());
  }

  int? _daysLeft(Map<String, dynamic> data) {
    final ts = data['subscriptionEnd'];
    if (ts == null || ts is! Timestamp) return null;
    final end = ts.toDate();
    final now = DateTime.now();
    final diff = end.difference(now).inDays;
    return diff;
  }

  bool _isExpiringSoon(Map<String, dynamic> data) {
    if (!_isActive(data)) return false;
    final days = _daysLeft(data);
    if (days == null) return false;
    return days <= 7;
  }

  /// تطبيق فلتر الواجهة (على الكلاينت بعد الجلب)
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

  /// مطابقة البحث (اسم/إيميل) — غيّر الحقول حسب ما لديك
  bool _matchesSearch(Map<String, dynamic> data) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final name = (data['name'] ?? '').toString().toLowerCase();
    final email = (data['email'] ?? '').toString().toLowerCase();
    return name.contains(q) || email.contains(q);
  }

  Future<void> _activateFor(
    String userId, {
    required Duration duration,
    String? plan,
  }) async {
    final now = DateTime.now();
    final end = now.add(duration);

    // ------------- 👇 طباعة التثبت قبل التحديث -------------
    print('SUBS UPDATE → path=users/$userId, payload=');
    print({
      'subscriptionActive': true,
      'subscriptionEnd': 'TIMESTAMP(${end.toIso8601String()})',
      'subscriptionPlan': plan ?? 'manual',
      'subscriptionUpdatedAt': 'serverTimestamp',
    });
    // -------------------------------------------------------

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'subscriptionActive': true,
      'subscriptionEnd': Timestamp.fromDate(end),
      'subscriptionPlan': plan ?? 'manual',
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تفعيل الاشتراك حتى ${_fmtDate(end)}')),
    );
  }

  Future<void> _activateCustomDialog(String userId) async {
    final controller = TextEditingController(text: '30');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Duration>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تفعيل لمدة مخصصة'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الأيام',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = int.tryParse(v?.trim() ?? '');
                if (value == null || value <= 0) return 'أدخل عدد أيام صحيح';
                if (value > 3650) return 'القيمة كبيرة جدًا';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final days = int.parse(controller.text.trim());
                  Navigator.pop(ctx, Duration(days: days));
                }
              },
              child: const Text('تفعيل'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _activateFor(userId, duration: result, plan: 'custom');
    }
  }

  Future<void> _deactivate(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعطيل الاشتراك'),
        content: const Text('هل أنت متأكد من تعطيل اشتراك هذا الطبيب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'subscriptionActive': false,
      // حذف تاريخ النهاية (اختياري)
      'subscriptionEnd': FieldValue.delete(),
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تعطيل الاشتراك')));
  }

  String _fmtDate(DateTime dt) {
    // صيغة بسيطة YYYY-MM-DD
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('الكل'),
          selected: _filter == SubFilter.all,
          onSelected: (_) => setState(() => _filter = SubFilter.all),
        ),
        ChoiceChip(
          label: const Text('نشط'),
          selected: _filter == SubFilter.active,
          onSelected: (_) => setState(() => _filter = SubFilter.active),
        ),
        ChoiceChip(
          label: const Text('غير نشط/منتهي'),
          selected: _filter == SubFilter.inactive,
          onSelected: (_) => setState(() => _filter = SubFilter.inactive),
        ),
        ChoiceChip(
          label: const Text('ينتهي قريبًا (≤ 7 أيام)'),
          selected: _filter == SubFilter.expiringSoon,
          onSelected: (_) => setState(() => _filter = SubFilter.expiringSoon),
        ),
      ],
    );
  }

  PopupMenuButton<int> _actionsMenu(String userId, Map<String, dynamic> data) {
    final isActiveNow = _isActive(data);

    return PopupMenuButton<int>(
      onSelected: (value) async {
        try {
          if (value == 7) {
            await _activateFor(
              userId,
              duration: const Duration(days: 7),
              plan: '7d',
            );
          } else if (value == 30) {
            await _activateFor(
              userId,
              duration: const Duration(days: 30),
              plan: '30d',
            );
          } else if (value == 90) {
            await _activateFor(
              userId,
              duration: const Duration(days: 90),
              plan: '90d',
            );
          } else if (value == 0) {
            await _activateCustomDialog(userId);
          } else if (value == -1) {
            await _deactivate(userId);
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('فشل الإجراء: $e')));
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 7, child: Text('تفعيل 7 أيام')),
        const PopupMenuItem(value: 30, child: Text('تفعيل 30 يومًا')),
        const PopupMenuItem(value: 90, child: Text('تفعيل 90 يومًا')),
        const PopupMenuItem(value: 0, child: Text('تفعيل لمدة مخصصة…')),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: -1,
          enabled: isActiveNow,
          child: const Text('تعطيل الاشتراك'),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة اشتراكات الأطباء')),
      body: Column(
        children: [
          // شريط البحث + الفلاتر
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو البريد…',
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
                  tooltip: 'تحديث',
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildFilterChips(),
          ),
          const Divider(height: 1),

          // القائمة
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _doctorsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('خطأ في التحميل: ${snap.error}'));
                }

                final docs = (snap.data?.docs ?? [])
                    .where((d) => _matchesSearch(d.data()))
                    .where((d) => _passesFilter(d.data()))
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج.'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final userId = doc.id;

                    final name = (data['name'] ?? 'بدون اسم').toString();
                    final email = (data['email'] ?? '').toString();

                    final active = _isActive(data);
                    final daysLeft = _daysLeft(data);
                    final endTs = data['subscriptionEnd'];
                    DateTime? endDate;
                    if (endTs is Timestamp) endDate = endTs.toDate();

                    String statusText;
                    Color? statusColor;

                    if (active) {
                      if (daysLeft != null) {
                        statusText =
                            'نشط — ${endDate != null ? _fmtDate(endDate) : ''} (متبقي $daysLeftيوم)';
                      } else {
                        statusText = 'نشط';
                      }
                      statusColor = Colors.green[700];
                    } else {
                      statusText =
                          (endDate != null && endDate.isBefore(DateTime.now()))
                          ? 'منتهي'
                          : 'غير نشط';
                      statusColor = Colors.red[700];
                    }

                    if (_isExpiringSoon(data)) {
                      statusColor = Colors.orange[800];
                      statusText += ' • ينتهي قريبًا';
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: const Icon(Icons.person, color: Colors.teal),
                      ),
                      title: Text(name, style: theme.textTheme.titleMedium),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (email.isNotEmpty)
                            Text(email, textDirection: TextDirection.ltr),
                          const SizedBox(height: 2),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing: _actionsMenu(userId, data),
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
