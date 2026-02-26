class Doctor {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String address;
  final String phone;
  final double price;
  final bool isPriceVisible;
  final bool isAvailable;
  final String? photoUrl;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.address,
    required this.phone,
    required this.price,
    required this.isPriceVisible,
    required this.isAvailable,
    this.photoUrl,
  });

  factory Doctor.fromMap(String id, Map<String, dynamic> data) {
    // تحويل آمن للـ rating (قد تكون int أو double أو null)
    final ratingRaw = data['rating'];
    final double rating = switch (ratingRaw) {
      int v => v.toDouble(),
      double v => v,
      String v => double.tryParse(v) ?? 0.0,
      _ => 0.0,
    };

    // تحويل آمن للـ price (num)
    final priceRaw = data['price'];
    final num price = switch (priceRaw) {
      int v => v,
      double v => v,
      String v => num.tryParse(v) ?? 0,
      _ => 0,
    };

    // تحويل آمن للحقول النصية (حتى لو دخلت كأرقام)
    String asString(dynamic v) => v?.toString() ?? '';

    // تحويل آمن للـ boolean
    final isAvailableRaw = data['isAvailable'];
    final bool isAvailable = switch (isAvailableRaw) {
      bool v => v,
      int v => v != 0,
      String v => v.toLowerCase() == 'true',
      _ => false,
    };

    return Doctor(
      id: id,
      name: asString(data['name']),
      specialty: asString(data['specialty']),
      rating: rating,
      address: asString(data['address']),
      phone: asString(data['phone']),
      price: (data['price'] ?? 0).toDouble(),
      isPriceVisible: data['isPriceVisible'] ?? false,
      isAvailable: data['isAvailable'] ?? true,

      photoUrl: (data['photoUrl'] == null || data['photoUrl'] == '')
          ? null
          : asString(data['photoUrl']),
    );
  }
}
