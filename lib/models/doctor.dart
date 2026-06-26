import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;

  final String name;

  final String specialtyId;
  final String? specialtyLabelAr;
  final String? specialtyLabelEn;
  final String? specialtyLabelFr;

  final String governorateId;
  final String governorateLabel;

  final String phone;
  final String address;

  final double rating;
  final double? price;
  final DateTime? subscriptionEnd;
  final DateTime? gracePeriodEnd;
  final bool isAvailable;
  final bool isPriceVisible;
  final bool subscriptionActive;
  final String? photoUrl;

  Doctor({
    required this.id,
    required this.name,

    required this.specialtyId,
    this.specialtyLabelAr,
    this.specialtyLabelEn,
    this.specialtyLabelFr,
    required this.governorateId,
    required this.governorateLabel,

    required this.phone,
    required this.address,
    required this.subscriptionActive,
    this.subscriptionEnd,
    this.gracePeriodEnd,
    required this.rating,
    this.price,

    required this.isAvailable,
    required this.isPriceVisible,

    this.photoUrl,
  });

  factory Doctor.fromMap(String id, Map<String, dynamic> data) {
    double asDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    String asString(dynamic v) => v?.toString() ?? '';

    final legacySpecialtyLabel = data['specialtyLabel']?.toString() ?? '';

    return Doctor(
      id: id,
      name: asString(data['name']),

      specialtyId: asString(data['specialtyId']),
      specialtyLabelAr:
          data['specialtyLabel_ar']?.toString() ?? legacySpecialtyLabel,
      specialtyLabelEn:
          data['specialtyLabel_en']?.toString() ?? legacySpecialtyLabel,
      specialtyLabelFr:
          data['specialtyLabel_fr']?.toString() ?? legacySpecialtyLabel,

      governorateId: asString(data['governorateId']),
      governorateLabel: asString(data['governorateLabel']),

      phone: asString(data['phone']),
      address: asString(data['address']),

      subscriptionActive: data['subscriptionActive'] ?? true,

      subscriptionEnd: data['subscriptionEnd'] != null
          ? (data['subscriptionEnd'] as Timestamp).toDate()
          : null,
      gracePeriodEnd: data['gracePeriodEnd'] != null
          ? (data['gracePeriodEnd'] as Timestamp).toDate()
          : null,

      rating: asDouble(data['rating']),
      price: data['price'] == null ? null : asDouble(data['price']),

      isAvailable: data['isAvailable'] ?? true,
      isPriceVisible: data['isPriceVisible'] ?? false,

      photoUrl: (data['photoUrl'] == null || data['photoUrl'] == '')
          ? null
          : asString(data['photoUrl']),
    );
  }
}
