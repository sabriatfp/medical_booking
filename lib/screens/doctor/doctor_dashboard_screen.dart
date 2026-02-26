import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_service.dart';

enum DocApptFilter { all, pending, confirmed, canceled }

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DoctorService _doctorService = DoctorService();
  DocApptFilter _filter = DocApptFilter.all;

  String? _statusFromFilter() {
    switch (_filter) {
      case DocApptFilter.pending:
        return 'pending';
      case DocApptFilter.confirmed:
        return 'confirmed';
      case DocApptFilter.canceled:
        return 'canceled';
      case DocApptFilter.all:
      default:
        return null;
    }
  }

  Future<void> _callNumber(String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الطبيب')),
      body: FutureBuilder<String?>(
        future: _doctorService.getDoctorId(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctorId = snap.data;
          if (doctorId == null) {
            return const Center(child: Text('لم يتم ربط الحساب بطبيب'));
          }

          return Column(
            children: [
              _filterChips(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _doctorService.appointmentsStream(
                    doctorId,
                    _statusFromFilter(),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('خطأ في تحميل المواعيد'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(child: Text('لا توجد مواعيد'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        final dt = (d['dateTime'] as Timestamp).toDate();

                        final patientName = d['patientName'] ?? '';
                        final patientPhone = d['patientPhone'] ?? '';
                        final status = d['status'] ?? 'pending';

                        Color statusColor = status == 'confirmed'
                            ? Colors.green
                            : status == 'canceled'
                                ? Colors.red
                                : Colors.orange;

                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            leading: const Icon(Icons.calendar_month),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    patientName.isEmpty
                                        ? "مريض"
                                        : patientName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status == 'confirmed'
                                        ? 'مؤكّد'
                                        : status == 'canceled'
                                            ? 'ملغى'
                                            : 'قيد الانتظار',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  "
                                "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}\n"
                                "الهاتف: ${patientPhone.isEmpty ? 'غير متوفر' : patientPhone}",
                              ),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'confirm') {
                                  await _doctorService.updateAppointmentStatus(
                                      docs[i].id, 'confirmed');
                                } else if (v == 'cancel') {
                                  await _doctorService.updateAppointmentStatus(
                                      docs[i].id, 'canceled');
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'confirm',
                                    child: Text('تأكيد الموعد')),
                                PopupMenuItem(
                                    value: 'cancel',
                                    child: Text('إلغاء الموعد')),
                              ],
                              icon: const Icon(Icons.more_vert),
                            ),
                            onTap: () => _callNumber(patientPhone),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip('الكل', DocApptFilter.all),
        _chip('قيد الانتظار', DocApptFilter.pending),
        _chip('مؤكّد', DocApptFilter.confirmed),
        _chip('ملغى', DocApptFilter.canceled),
      ],
    );
  }

  Widget _chip(String label, DocApptFilter value) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}
