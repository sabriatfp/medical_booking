// lib/admin/ui/admin_reports_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

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
  String? _typeFilter;
  Set<String> _seenReports = {};

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

  bool _passesStatus(Map<String, dynamic> data, AppLocalizations t) {
    final status = (data['status'] ?? 'new').toString();
    return switch (_statusFilter) {
      ReportFilter.all => true,
      ReportFilter.newOnly => status == 'new',
      ReportFilter.processed => status == 'processed',
    };
  }

  bool _passesType(Map<String, dynamic> data) {
    if (_typeFilter == null || _typeFilter!.isEmpty) return true;
    return (data['type'] ?? '').toString() == _typeFilter;
  }

  bool _passesDate(Map<String, dynamic> data) {
    if (_dateRange == null) return true;
    final ts = data['createdAt'];
    if (ts is! Timestamp) return false;

    final dt = ts.toDate();

    final start = DateTime(
      _dateRange!.start.year,
      _dateRange!.start.month,
      _dateRange!.start.day,
      0,
      0,
      0,
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

  bool _passesSearch(Map<String, dynamic> data) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final type = (data['type'] ?? '').toLowerCase();
    final msg = (data['message'] ?? '').toLowerCase();
    final sender = (data['senderId'] ?? '').toLowerCase();

    return type.contains(q) || msg.contains(q) || sender.contains(q);
  }

  List<String> _extractTypes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final set = <String>{};

    for (final d in docs) {
      final t = (d.data()['type'] ?? '').toString();
      if (t.trim().isNotEmpty) set.add(t.trim());
    }

    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<void> _updateStatus(
    String reportId,
    String status,
    AppLocalizations t,
  ) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {'status': status},
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'processed' ? t.reportMarkedProcessed : t.reportMarkedNew,
        ),
      ),
    );
  }

  Future<void> _deleteReport(String id, AppLocalizations t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.deleteReport),
        content: Text(t.deleteReportConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseFirestore.instance.collection('reports').doc(id).delete();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.deletedSuccessfully)));
  }

  Future<void> _pickDateRange(AppLocalizations t) async {
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
      helpText: t.pickDateRange,
      cancelText: t.cancel,
      confirmText: t.confirm,
    );

    if (res != null) setState(() => _dateRange = res);
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
  }

  Future<void> _addReply(String reportId) async {
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Reply"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "Write reply..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Send"),
          ),
        ],
      ),
    );

    if (ok != true || controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {
        'reply': controller.text.trim(),
        'status': 'processed', // ✅ نغلقه مباشرة
        'replySeen': false, // ✅ مهم جدًا
      },
    );
  }

  // تفاصيل البلاغ
  Future<void> _showDetails(
    BuildContext context,
    String id, // ✅
    Map<String, dynamic> data,
    AppLocalizations t,
  ) async {
    final senderId = (data['senderId'] ?? '').toString();

    /// ✅ mark as read
    if ((data['status'] ?? 'new') == 'new') {
      await FirebaseFirestore.instance.collection('reports').doc(id).update({
        'status': 'processed',
      });
    }
    Future<String?> loadEmail() async {
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
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: FutureBuilder<String?>(
          future: loadEmail(),
          builder: (_, s) {
            final email = s.data ?? "";
            final type = (data['type'] ?? '').toString();
            final msg = (data['message'] ?? '').toString();
            final ts = data['createdAt'];
            final created = ts is Timestamp
                ? _formatDate(ts.toDate())
                : t.unknown;

            final status = (data['status'] ?? 'new').toString();
            final statusText = status == 'processed'
                ? t.processed
                : t.newReport;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.report, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          t.reportDetails,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),

                    _detailRow(t.type, type),
                    _detailRow(t.status, statusText),
                    _detailRow(t.date, created),
                    _detailRow("UID", senderId),

                    if (s.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),

                    if (email.isNotEmpty)
                      _detailRow(t.senderEmail, email, ltr: true),

                    const SizedBox(height: 8),
                    Text(
                      t.text,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(msg),

                    const SizedBox(height: 12),
                    Text(
                      t.noteStatusChangeHint,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  Widget _detailRow(String label, String value, {bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          const SizedBox(width: 6),
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

  PopupMenuButton<String> _rowActions(
    String id,
    Map<String, dynamic> data,
    AppLocalizations t,
  ) {
    final status = (data['status'] ?? 'new').toString();

    return PopupMenuButton<String>(
      onSelected: (v) async {
        if (v == 'processed') {
          await _updateStatus(id, 'processed', t);
        } else if (v == 'new') {
          await _updateStatus(id, 'new', t);
        } else if (v == 'delete') {
          await _deleteReport(id, t);
        } else if (v == 'reply') {
          await _addReply(id);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'processed',
          enabled: status != 'processed',
          child: Text(t.markProcessed),
        ),
        PopupMenuItem(
          value: 'new',
          enabled: status != 'new',
          child: Text(t.markNew),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'delete', child: Text(t.delete)),

        PopupMenuItem(
          value: 'reply',
          child: Row(
            children: const [
              Icon(Icons.reply, size: 18),
              SizedBox(width: 6),
              Text("Reply"),
            ],
          ),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.reports),
        actions: [
          IconButton(
            tooltip: t.refresh,
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

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
                      hintText: t.searchReports,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: _dateRange == null
                      ? t.pickDateRange
                      : t.clearDateRange,
                  onPressed: () => _dateRange == null
                      ? _pickDateRange(t)
                      : _clearDateRange(),
                  icon: Icon(
                    _dateRange == null ? Icons.date_range : Icons.event_busy,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(t.all),
                  selected: _statusFilter == ReportFilter.all,
                  onSelected: (_) =>
                      setState(() => _statusFilter = ReportFilter.all),
                ),
                ChoiceChip(
                  label: Text(t.newReport),
                  selected: _statusFilter == ReportFilter.newOnly,
                  onSelected: (_) =>
                      setState(() => _statusFilter = ReportFilter.newOnly),
                ),
                ChoiceChip(
                  label: Text(t.processed),
                  selected: _statusFilter == ReportFilter.processed,
                  onSelected: (_) =>
                      setState(() => _statusFilter = ReportFilter.processed),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _reportsStream(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(child: Text("${t.errorLoading} ${snap.error}"));
                }

                final all = snap.data?.docs ?? [];

                final types = _extractTypes(all);

                final filtered = all.where((d) {
                  final data = d.data();
                  return _passesStatus(data, t) &&
                      _passesType(data) &&
                      _passesDate(data) &&
                      _passesSearch(data);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text(t.noResults));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final doc = filtered[i];
                    final data = doc.data();
                    final id = doc.id;

                    final type = (data['type'] ?? t.report).toString();
                    final msg = (data['message'] ?? "").toString();

                    final senderName =
                        (data['senderName'] ?? "").toString().isNotEmpty
                        ? data['senderName']
                        : "Unknown doctor";

                    final ts = data['createdAt'];

                    final created = ts is Timestamp
                        ? _formatDate(ts.toDate())
                        : t.unknown;
                    final status = (data['status'] ?? 'new').toString();
                    final reply = data['reply'] ?? '';
                    final statusColor = status == 'processed'
                        ? Colors.green
                        : Colors.orange;
                    final statusText = status == 'processed'
                        ? t.processed
                        : t.newReport;
                    final isNew = !_seenReports.contains(id);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: const Icon(Icons.report, color: Colors.teal),
                      ),
                      title: Text(type),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.isNotEmpty)
                            Text(
                              msg,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            "${t.sender}: $senderName • $created",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          /// ✅ ✅ ✅ NEW: إذا يوجد رد
                          if (reply.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "↳ ${t.replyAdded}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _rowActions(id, data, t),

                          /// ✅ النقطة الحمراء
                          if (status == 'new')
                            Positioned(
                              right: -3,
                              top: -3,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _seenReports.add(id);
                        });

                        _showDetails(context, id, data, t);
                      },
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
