import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';

class AdminMaintenanceScreen extends StatefulWidget {
  const AdminMaintenanceScreen({super.key});

  @override
  State<AdminMaintenanceScreen> createState() => _AdminMaintenanceScreenState();
}

class _AdminMaintenanceScreenState extends State<AdminMaintenanceScreen> {
  bool loading = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= RESET APPOINTMENTS =================
  Future<void> clearAppointments() async {
    final t = AppLocalizations.of(context)!;
    setState(() => loading = true);

    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .get();

    for (var doc in snap.docs) {
      await doc.reference.delete();
    }

    setState(() => loading = false);

    _showSnack("✅ ${t.appointmentsCleared}");
  }

  // ================= RESET SLOTS =================
  Future<void> clearSlots() async {
    final t = AppLocalizations.of(context)!;
    setState(() => loading = true);

    final snap = await FirebaseFirestore.instance
        .collection('doctor_slots')
        .get();

    for (var doc in snap.docs) {
      await doc.reference.delete();
    }

    setState(() => loading = false);

    _showSnack("✅ ${t.slotsCleared}");
  }

  // ================= RESET TRANSACTIONS =================
  Future<void> clearTransactions() async {
    final t = AppLocalizations.of(context)!;
    setState(() => loading = true);

    final snap = await FirebaseFirestore.instance
        .collection('financial_transactions')
        .get();

    for (var doc in snap.docs) {
      await doc.reference.delete();
    }

    setState(() => loading = false);
    _showSnack("✅ ${t.transactionsCleared}");
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.adminMaintenance)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (loading) const LinearProgressIndicator(),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: clearAppointments,
              child: Text(t.resetAppointments),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: clearSlots,
              child: Text(t.resetSlots),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: clearTransactions,
              child: Text(t.resetTransactions),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 20),

            Text(
              "⚠️ ${t.dangerZone}",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: loading
                    ? null
                    : () async {
                        final ok = await confirmFullReset();
                        if (ok) {
                          fullReset();
                        }
                      },
                child: Text(
                  "🔥 ${t.fullReset}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> confirmFullReset() async {
    final t = AppLocalizations.of(context)!;
    final first = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.warningTitle),
        content: Text(t.warningMessage),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.continueBtn),
          ),
        ],
      ),
    );

    if (first != true) return false;

    final second = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.finalConfirm),
        content: Text(t.finalMessage),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    return second == true;
  }

  Future<void> fullReset() async {
    setState(() => loading = true);
    final t = AppLocalizations.of(context)!;
    final db = FirebaseFirestore.instance;

    final collections = [
      'appointments',
      'doctor_slots',
      'financial_transactions',
    ];

    for (var col in collections) {
      final snap = await db.collection(col).get();

      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    setState(() => loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("🔥 ${t.resetDone}")));
  }
}
