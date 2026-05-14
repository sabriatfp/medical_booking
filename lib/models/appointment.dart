class Appointment {
  final String id;

  final String patientId; // ✅ بدل userId
  final String doctorId;
  final DateTime dateTime;
  final String status; // pending, confirmed, canceled
  final DateTime? createdAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateTime,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'dateTime': dateTime.toUtc(), // نحفظها UTC لتفادي مشاكل التوقيت
      'status': status,
      'createdAt': DateTime.now().toUtc(),
    };
  }

  static Appointment fromMap(String id, Map<String, dynamic> data) {
    final ts = data['dateTime'];
    final DateTime dt = ts is DateTime
        ? ts
        : (ts is String ? DateTime.parse(ts) : DateTime.now());

    final createdRaw = data['createdAt'];
    final created = createdRaw is DateTime
        ? createdRaw
        : (createdRaw is String ? DateTime.tryParse(createdRaw) : null);

    return Appointment(
      id: id,
      patientId: data['userId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      dateTime: dt.toLocal(),
      status: data['status'] ?? 'pending',
      createdAt: created?.toLocal(),
    );
  }
}
