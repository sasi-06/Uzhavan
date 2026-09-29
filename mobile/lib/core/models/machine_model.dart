import 'user_model.dart';

class MachineModel {
  MachineModel({
    required this.id,
    required this.type,
    this.model,
    this.pricePerHour,
    this.pricePerAcre,
    required this.operatorIncluded,
    required this.status,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.photos = const [],
    this.owner,
    this.village,
    this.district,
    this.lastServiceDate,
    this.serviceIntervalMonths,
    this.horsepower,
  });

  final String id;
  final String type;
  final String? model;
  final double? pricePerHour;
  final double? pricePerAcre;
  final bool operatorIncluded;
  final String status;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final List<String> photos;
  final UserModel? owner;
  final String? village;
  final String? district;
  final String? lastServiceDate;
  final num? serviceIntervalMonths;
  final int? horsepower;

  int get effectiveHorsepower {
    if (horsepower != null && horsepower! > 0) return horsepower!;
    final m = (model ?? '').toLowerCase();
    if (m.contains('575') || m.contains('475')) return 45;
    if (m.contains('5050') || m.contains('5310')) return 50;
    if (m.contains('744') || m.contains('735')) return 48;
    if (m.contains('241') || m.contains('1035')) return 42;
    if (m.contains('harvester') || type.toLowerCase().contains('harvester')) return 75;
    return 45;
  }

  bool get isOverdueForServicing {
    if (lastServiceDate == null || serviceIntervalMonths == null) return false;
    try {
      final lastService = DateTime.parse(lastServiceDate!);
      final nextService = DateTime(
        lastService.year,
        lastService.month + serviceIntervalMonths!.toInt(),
        lastService.day,
      );
      return DateTime.now().isAfter(nextService);
    } catch (_) {
      return false;
    }
  }

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    UserModel? ownerObj;
    if (json['owner'] != null && json['owner'] is Map<String, dynamic>) {
      ownerObj = UserModel.fromJson(json['owner'] as Map<String, dynamic>);
    } else {
      final name = (json['ownerName'] ?? json['owner_name'] ?? json['contactName'] ?? json['name'] ?? '').toString();
      final phone = (json['ownerPhone'] ?? json['owner_phone'] ?? json['contactPhone'] ?? json['phone'] ?? json['mobile'] ?? '').toString();
      final id = (json['ownerId'] ?? json['owner_id'] ?? json['userId'] ?? json['user_id'] ?? 'owner_default').toString();
      ownerObj = UserModel(
        id: id.isNotEmpty ? id : 'owner_default',
        name: name.isNotEmpty ? name : 'உரிமையாளர் / Machine Owner',
        phone: phone.isNotEmpty ? phone : '+91 98765 43210',
        role: 'owner',
        preferredLanguage: 'ta',
        kycStatus: 'verified',
      );
    }

    return MachineModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'tractor').toString(),
      model: json['model'] as String?,
      pricePerHour: _toDouble(json['pricePerHour']),
      pricePerAcre: _toDouble(json['pricePerAcre']),
      operatorIncluded: json['operatorIncluded'] as bool? ?? false,
      status: (json['status'] ?? 'active').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      distanceKm: _toDouble(json['distanceKm']),
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
      owner: ownerObj,
      village: json['village']?.toString() ?? json['owner']?['village']?.toString(),
      district: json['district']?.toString() ?? json['owner']?['district']?.toString(),
      lastServiceDate: json['lastServiceDate'] as String?,
      serviceIntervalMonths: json['serviceIntervalMonths'] as num?,
      horsepower: json['horsepower'] != null ? (json['horsepower'] as num).toInt() : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String get displayPrice {
    if (pricePerAcre != null) return '₹${pricePerAcre!.toStringAsFixed(0)}/acre';
    if (pricePerHour != null) return '₹${pricePerHour!.toStringAsFixed(0)}/hr';
    return 'Price on request';
  }
}
