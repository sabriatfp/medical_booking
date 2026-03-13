import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

enum ReportFilter { all, newOnly, processed }

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _searchCtrl = TextEditingController();
  ReportFilter _statusFilter = ReportFilter.all;

  DateTimeRange? _dateRange;
  String? _typeFilter; // null = كل الأنواع

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // المصدر: أحدث البلاغات أولًا
  Stream<QuerySnapshot<Map<String, dynamic>>> _reportsStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // تصفية حسب الحالة
  bool _passesStatus(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'new').toString();
    switch (_statusFilter) {
      case ReportFilter.all:
        return true;
      case ReportFilter.newOnly:
        return status == 'new';
      case ReportFilter.processed:
        return status == 'processed';
    }
  }

  // تصفية حسب النوع
  bool _passesType(Map<String, dynamic> data) {
    if (_typeFilter == null || _typeFilter!.isEmpty) return true;
    final t = (data['type'] ?? '').toString();
    return t == _typeFilter;
  }

  // تصفية حسب التاريخ
  bool _passesDate(Map<String, dynamic> data) {
    if (_dateRange == null) return true;
    final ts = data['createdAt'];
    if (ts is! Timestamp) return false;
    final dt = ts.toDate();
    // نضمّن اليومين طرفي المدى
    final start = DateTime(
      _dateRange!.start.year,
      _dateRange!.start.month,
      _dateRange!.start.day,
    );
    final end = DateTime(
      _dateRange!.end.year,
      _dateRange!.end.month,
      _dateRange!.end.day,
      23,
      59,
      59,
    );
    return dt.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
        dt.isBefore(end.add(const Duration(milliseconds: 1)));
  }

  // بحث نصّي بسيط في النوع/الرسالة/المرسل
  bool _passesSearch(Map<String, dynamic> data) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final type = (data['type'] ?? '').toString().toLowerCase();
    final msg = (data['message'] ?? '').toString().toLowerCase();
    final sender = (data['senderId'] ?? '').toString().toLowerCase();
    return type.contains(q) || msg.contains(q) || sender.contains(q);
  }

  List<String> _extractTypes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final set = <String>{};
    for (final d in docs) {
      final t = (d.data()['type'] ?? '').toString().trim();
      if (t.isNotEmpty) set.add(t);
    }
    final types = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return types;
  }

  Future<void> _updateStatus(String reportId, String status) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {
        'status': status, // فقط هذا الحقل بما يتوافق مع القواعد
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'processed' ? 'تمّت المعالجة' : 'تم إرجاع الحالة إلى جديد',
        ),
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف البلاغ'),
        content: const Text('هل تريد حذف هذا البلاغ نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .delete();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم الحذف')));
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = DateTimeRange(
      start: _dateRange?.start ?? now.subtract(const Duration(days: 7)),
      end: _dateRange?.end ?? now,
    );
    final res = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
      helpText: 'اختر مدى التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (res != null) {
      setState(() => _dateRange = res);
    }
  }

  void _clearDateRange() => setState(() => _dateRange = null);

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Widget _statusChips() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('الكل'),
          selected: _statusFilter == ReportFilter.all,
          onSelected: (_) => setState(() => _statusFilter = ReportFilter.all),
        ),
        ChoiceChip(
          label: const Text('جديد'),
          selected: _statusFilter == ReportFilter.newOnly,
          onSelected: (_) =>
              setState(() => _statusFilter = ReportFilter.newOnly),
        ),
        ChoiceChip(
          label: const Text('تمت المعالجة'),
          selected: _statusFilter == ReportFilter.processed,
          onSelected: (_) =>
              setState(() => _statusFilter = ReportFilter.processed),
        ),
      ],
    );
  }

  PopupMenuButton<String> _rowActions(String id, Map<String, dynamic> data) {
    final current = (data['status'] ?? 'new').toString();
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'processed') {
          await _updateStatus(id, 'processed');
        } else if (value == 'new') {
          await _updateStatus(id, 'new');
        } else if (value == 'delete') {
          await _deleteReport(id);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'processed',
          enabled: current != 'processed',
          child: const Text('تعليم "تمّت المعالجة"'),
        ),
        PopupMenuItem(
          value: 'new',
          enabled: current != 'new',
          child: const Text('إرجاع إلى "جديد"'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: Text('حذف')),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final senderId = (data['senderId'] ?? '').toString();
    // نجلب بريد المرسل عند الحاجة فقط
    Future<String?> loadSenderEmail() async {
      if (senderId.isEmpty) return null;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();
      if (!snap.exists) return null;
      return (snap.data()?['email'] ?? '').toString();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: FutureBuilder<String?>(
            future: loadSenderEmail(),
            builder: (ctx2, s) {
              final email = (s.data ?? '').toString();
              final type = (data['type'] ?? '').toString();
              final msg = (data['message'] ?? '').toString();
              final ts = data['createdAt'];
              final created = ts is Timestamp ? _formatDate(ts.toDate()) : '-';
              final status = (data['status'] ?? 'new').toString();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.report, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            'تفاصيل البلاغ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(),
                      _detailRow('النوع', type),
                      _detailRow(
                        'الحالة',
                        status == 'processed' ? 'تمّت المعالجة' : 'جديد',
                      ),
                      _detailRow('التاريخ', created),
                      _detailRow('المرسل (UID)', senderId),
                      if (s.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (email.isNotEmpty)
                        _detailRow('بريد المرسل', email, ltr: true),
                      const SizedBox(height: 8),
                      const Text(
                        'النص:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(msg),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ملاحظة: تعديل الحالة يتم من قائمة السطر الرئيسية.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('البلاغات'),
        actions: [
          IconButton(
            tooltip: 'إعادة تحميل',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث + فلاتر الحالة/النوع/التاريخ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث في النوع/النص/المُرسل…',
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
                  tooltip: _dateRange == null
                      ? 'تحديد مدى التاريخ'
                      : 'مسح مدى التاريخ',
                  onPressed: () =>
                      _dateRange == null ? _pickDateRange() : _clearDateRange(),
                  icon: Icon(
                    _dateRange == null ? Icons.date_range : Icons.event_busy,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _statusChips(),
          ),
          const Divider(height: 1),

          // القائمة
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _reportsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('خطأ في التحميل: ${snap.error}'));
                }

                final allDocs = snap.data?.docs ?? [];

                // تحضير قائمة الأنواع لتسهيل الفلترة
                final types = _extractTypes(allDocs);
                // شريط فلتر النوع (اختياري)
                final typeFilterBar = (types.isEmpty)
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('كل الأنواع'),
                                selected: _typeFilter == null,
                                onSelected: (_) =>
                                    setState(() => _typeFilter = null),
                              ),
                              const SizedBox(width: 8),
                              ...types.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(t),
                                    selected: _typeFilter == t,
                                    onSelected: (_) =>
                                        setState(() => _typeFilter = t),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                // تطبيق الفلاتر والبحث على الكلاينت
                final filtered = allDocs.where((d) {
                  final data = d.data();
                  return _passesStatus(data) &&
                      _passesType(data) &&
                      _passesDate(data) &&
                      _passesSearch(data);
                }).toList();

                if (filtered.isEmpty) {
                  return Column(
                    children: [
                      typeFilterBar,
                      const Expanded(
                        child: Center(child: Text('لا توجد بلاغات مطابقة.')),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    typeFilterBar,
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data();
                          final id = doc.id;

                          final type = (data['type'] ?? '').toString();
                          final msg = (data['message'] ?? '').toString();
                          final senderId = (data['senderId'] ?? '').toString();
                          final ts = data['createdAt'];
                          final created = ts is Timestamp
                              ? _formatDate(ts.toDate())
                              : '-';
                          final status = (data['status'] ?? 'new').toString();

                          final statusColor = status == 'processed'
                              ? Colors.green[700]
                              : Colors.orange[800];
                          final statusText = status == 'processed'
                              ? 'تمّت المعالجة'
                              : 'جديد';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: const Icon(
                                Icons.report,
                                color: Colors.teal,
                              ),
                            ),
                            title: Text(
                              type.isEmpty ? 'بلاغ' : type,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (msg.isNotEmpty)
                                  Text(
                                    msg,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  'المرسل: $senderId • $created',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  textDirection: TextDirection.ltr,
                                ),
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
                            trailing: _rowActions(id, data),
                            onTap: () => _showDetails(context, data),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
