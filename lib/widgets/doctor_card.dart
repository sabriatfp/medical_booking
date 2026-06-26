import 'package:flutter/material.dart';
import 'package:medical_booking/generated_l10n/app_localizations.dart';
import '../models/doctor.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final bool isExpired;
  final int? remainingDays;
  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.isExpired = false,
    this.remainingDays,
  });
  bool _canBookDoctor() {
    return doctor.isAvailable;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===============================
              // ✅ Avatar
              // ===============================
              CircleAvatar(
                radius: 26,
                backgroundImage:
                    (doctor.photoUrl != null && doctor.photoUrl!.isNotEmpty)
                    ? NetworkImage(doctor.photoUrl!)
                    : null,
                child: (doctor.photoUrl == null || doctor.photoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),

              const SizedBox(width: 12),

              // ===============================
              // ✅ Infos
              // ===============================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم + badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${t.doctorPrefix} ${doctor.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _availabilityBadge(t),
                      ],
                    ),

                    const SizedBox(height: 4),
                    if (isExpired && remainingDays != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t.remainingDays(remainingDays ?? 0),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    // الاختصاص
                    Text(
                      _localizedSpecialty(context),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                    const SizedBox(height: 6),

                    // التقييم + السعر
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13),
                        ),

                        if (doctor.isPriceVisible && doctor.price != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${doctor.price!.toStringAsFixed(0)} د.ت',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // زر الحجز
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _canBookDoctor()
                            ? t.bookAppointment
                            : doctor.isAvailable
                            ? t.bookAppointment
                            : t.doctorNotAvailable,

                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _canBookDoctor() ? Colors.blue : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedSpecialty(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;

    switch (lang) {
      case 'ar':
        return (doctor.specialtyLabelAr?.isNotEmpty ?? false)
            ? doctor.specialtyLabelAr!
            : (doctor.specialtyLabelFr ?? '');

      case 'en':
        return (doctor.specialtyLabelEn?.isNotEmpty ?? false)
            ? doctor.specialtyLabelEn!
            : (doctor.specialtyLabelFr ?? '');

      case 'fr':
      default:
        return doctor.specialtyLabelFr ?? '';
    }
  }

  // ===============================
  // ✅ Badge الحالة
  // ===============================
  Widget _availabilityBadge(AppLocalizations t) {
    return doctor.isAvailable
        ? _badge(t.available, Colors.green, Icons.check_circle)
        : _badge(t.notAvailable, Colors.red, Icons.cancel);
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
