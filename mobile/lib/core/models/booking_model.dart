import 'user_model.dart';

class BookingModel {
  BookingModel({
    required this.id,
    required this.machineId,
    required this.status,
    required this.priceTotal,
    required this.startDate,
    required this.endDate,
    this.machineType,
    this.operatorIncluded = false,
    this.renter,
    this.owner,
    this.farmerLat,
    this.farmerLng,
    this.farmerVillage,
  });

  final String id;
  final String machineId;
  final String status;
  final double priceTotal;
  final DateTime startDate;
  final DateTime endDate;
  final String? machineType;
  final bool operatorIncluded;
  final UserModel? renter;
  final UserModel? owner;
  final double? farmerLat;
  final double? farmerLng;
  final String? farmerVillage;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final machine = json['machine'] as Map<String, dynamic>?;
    final ownerMap = json['owner'] as Map<String, dynamic>? ?? machine?['owner'] as Map<String, dynamic>?;
    final renterMap = json['renter'] as Map<String, dynamic>?;

    final double? lat = _toDouble(json['farmerLat'] ?? json['farmerLocation']?['lat'] ?? json['location']?['lat'] ?? renterMap?['latitude']);
    final double? lng = _toDouble(json['farmerLng'] ?? json['farmerLocation']?['lng'] ?? json['location']?['lng'] ?? renterMap?['longitude']);
    final String? village = json['farmerVillage'] as String? ?? json['village'] as String? ?? renterMap?['village'] as String?;

    return BookingModel(
      id: (json['id'] ?? '').toString(),
      machineId: (json['machineId'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      priceTotal: _toDouble(json['priceTotal']) ?? 0,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      machineType: (machine?['type'] ?? json['machineType'] ?? 'tractor').toString(),
      operatorIncluded: json['operatorIncluded'] as bool? ?? false,
      renter: json['renter'] != null ? UserModel.fromJson(json['renter'] as Map<String, dynamic>) : null,
      owner: ownerMap != null ? UserModel.fromJson(ownerMap) : null,
      farmerLat: lat,
      farmerLng: lng,
      farmerVillage: village,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch((value['seconds'] as num).toInt() * 1000);
    }
    try {
      if ((value as dynamic).toDate != null) {
        return (value as dynamic).toDate();
      }
    } catch (_) {}
    return DateTime.now();
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
