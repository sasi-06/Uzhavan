class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.preferredLanguage,
    required this.kycStatus,
    this.village,
    this.district,
    this.latitude,
    this.longitude,
    this.emergencyName,
    this.emergencyPhone,
    this.emergencyRelation,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String preferredLanguage;
  final String kycStatus;
  final String? village;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? emergencyRelation;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] ?? json['ownerId'] ?? json['user_id'] ?? '').toString(),
        name: (json['name'] ?? json['ownerName'] ?? json['fullName'] ?? '').toString(),
        phone: (json['phone'] ?? json['ownerPhone'] ?? json['phoneNumber'] ?? json['mobile'] ?? '').toString(),
        role: (json['role'] ?? 'owner').toString(),
        preferredLanguage: (json['preferredLanguage'] ?? 'ta').toString(),
        kycStatus: (json['kycStatus'] ?? 'verified').toString(),
        village: json['village']?.toString(),
        district: json['district']?.toString(),
        latitude: _toDouble(json['latitude'] ?? json['lat']),
        longitude: _toDouble(json['longitude'] ?? json['lng']),
        emergencyName: json['emergencyName']?.toString(),
        emergencyPhone: json['emergencyPhone']?.toString(),
        emergencyRelation: json['emergencyRelation']?.toString(),
      );

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
