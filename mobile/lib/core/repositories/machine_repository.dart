import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../api/api_client.dart';
import '../models/machine_model.dart';

class MachineRepository {
  MachineRepository(this._api);
  final ApiClient _api;

  final _db = FirebaseFirestore.instance;

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p)/2 + 
          cos(lat1 * p) * cos(lat2 * p) * 
          (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  static final List<Map<String, dynamic>> _seedMachines = [
    {
      'id': 'm_tractor_01',
      'type': 'tractor',
      'model': 'Mahindra 575 DI (45 HP Tractor)',
      'pricePerHour': 850.0,
      'pricePerAcre': 1200.0,
      'operatorIncluded': true,
      'status': 'active',
      'latitude': 9.1730,
      'longitude': 77.8680,
      'distanceKm': 3.2,
      'photos': ['https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600&auto=format&fit=crop'],
      'owner': {
        'id': 'owner_ramesh',
        'name': 'ரமேஷ் குமார் / Ramesh Kumar',
        'phone': '+91 98401 23456',
        'role': 'owner',
        'preferredLanguage': 'ta',
        'kycStatus': 'verified',
      },
    },
    {
      'id': 'm_tractor_02',
      'type': 'tractor',
      'model': 'Sonalika International DI 745 III (50 HP)',
      'pricePerHour': 900.0,
      'pricePerAcre': 1300.0,
      'operatorIncluded': true,
      'status': 'active',
      'latitude': 9.1352,
      'longitude': 78.1714,
      'distanceKm': 4.5,
      'photos': [],
      'owner': {
        'id': 'owner_kannan',
        'name': 'கண்ணன் வேலு / Kannan Velu',
        'phone': '+91 94441 88776',
        'role': 'owner',
        'preferredLanguage': 'ta',
        'kycStatus': 'verified',
      },
    },
    {
      'id': 'm_harvester_01',
      'type': 'harvester',
      'model': 'Preet 987 Paddy Harvester',
      'pricePerHour': 1600.0,
      'pricePerAcre': 2400.0,
      'operatorIncluded': true,
      'status': 'active',
      'latitude': 8.7642,
      'longitude': 78.1348,
      'distanceKm': 5.8,
      'photos': ['https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=600&auto=format&fit=crop'],
      'owner': {
        'id': 'owner_selvam',
        'name': 'செல்வம் முருகன் / Selvam Murugan',
        'phone': '+91 97890 56789',
        'role': 'owner',
        'preferredLanguage': 'ta',
        'kycStatus': 'verified',
      },
    },
    {
      'id': 'm_plough_01',
      'type': 'plough',
      'model': 'Sonalika 3-Disc Rotary Plough',
      'pricePerHour': 750.0,
      'pricePerAcre': 1100.0,
      'operatorIncluded': true,
      'status': 'active',
      'latitude': 8.6186,
      'longitude': 77.9897,
      'distanceKm': 4.1,
      'photos': [],
      'owner': {
        'id': 'owner_karthik',
        'name': 'கார்த்திக் ராஜா / Karthik Raja',
        'phone': '+91 94440 11223',
        'role': 'owner',
        'preferredLanguage': 'ta',
        'kycStatus': 'verified',
      },
    },
    {
      'id': 'm_seeder_01',
      'type': 'seeder',
      'model': 'Fieldking Automatic Seed Drill',
      'pricePerHour': 650.0,
      'pricePerAcre': 950.0,
      'operatorIncluded': false,
      'status': 'active',
      'latitude': 9.0500,
      'longitude': 77.7500,
      'distanceKm': 6.5,
      'photos': [],
      'owner': {
        'id': 'owner_muthu',
        'name': 'முத்துவேல் / Muthuvel',
        'phone': '+91 98840 99887',
        'role': 'owner',
        'preferredLanguage': 'ta',
        'kycStatus': 'verified',
      },
    },
    {
      'id': 'm_sprayer_01',
      'type': 'sprayer',
      'model': 'TAFE Boom Crop Sprayer 500L',
      'pricePerHour': 550.0,
      'pricePerAcre': 800.0,
      'operatorIncluded': true,
      'status': 'active',
      'latitude': 9.1730,
      'longitude': 78.0200,
      'distanceKm': 2.9,
      'photos': [],
      'owner': {
        'id': 'owner_arun',
        'name': 'அருண் பாண்டியன் / Arun Pandian',
        'phone': '+91 97100 44332',
        'role': 'owner',
        'preferredLanguage': 'ta',
        'kycStatus': 'verified',
      },
    },
  ];

  /// Check if a machine is available for the given date range.
  /// Returns true if no booked dates conflict with [startDate]..[endDate].
  bool _isAvailableForDates(Map<String, dynamic> data, DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return true;
    final blocked = data['blockedDates'] as List<dynamic>? ?? [];
    for (final b in blocked) {
      if (b is! Map) continue;
      final bStart = DateTime.tryParse(b['startDate']?.toString() ?? '');
      final bEnd = DateTime.tryParse(b['endDate']?.toString() ?? '');
      if (bStart == null || bEnd == null) continue;
      // Overlap check: requested overlaps with blocked if start <= bEnd && end >= bStart
      if (startDate.isBefore(bEnd.add(const Duration(days: 1))) &&
          endDate.isAfter(bStart.subtract(const Duration(days: 1)))) {
        return false;
      }
    }
    return true;
  }

  Future<List<MachineModel>> search({
    required double latitude,
    required double longitude,
    String? type,
    double radiusKm = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final List<MachineModel> list = [];
    final Set<String> seenIds = {};

    // ── Layer 1: Try REST Backend API (NestJS backend via ApiClient) ──
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radiusKm': radiusKm.toString(),
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
      };
      dynamic res;
      try {
        res = await _api.get('/machines/search', query: queryParams);
      } catch (_) { res = null; }
      if (res != null) {
        List<dynamic> rawList = [];
        if (res is List) {
          rawList = res;
        } else if (res is Map && res['data'] is List) {
          rawList = res['data'] as List;
        }
        for (final item in rawList) {
          final data = Map<String, dynamic>.from(item as Map);
          final id = data['id']?.toString() ?? '';
          if (id.isNotEmpty && !seenIds.contains(id)) {
            seenIds.add(id);
            final lat = _toDouble(data['latitude'] ?? data['location']?['lat']) ?? latitude;
            final lng = _toDouble(data['longitude'] ?? data['location']?['lng']) ?? longitude;
            data['distanceKm'] = _calculateDistance(latitude, longitude, lat, lng);
            if (!_isAvailableForDates(data, startDate, endDate)) continue;
            await _populateOwner(data);
            list.add(MachineModel.fromJson(data));
          }
        }
      }
    } catch (e) {
      print('REST API search error suppressed: $e');
    }

    // ── Layer 2: Try Firebase Cloud Function (if REST API yielded no results) ────
    if (list.isEmpty && !kIsWeb) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('searchNearbyMachines');
        dynamic result;
        try {
          result = await callable.call({
            'lat': latitude,
            'lng': longitude,
            'radius': radiusKm,
          });
        } catch (_) { result = null; }
        if (result != null && result.data != null && result.data['success'] == true) {
          final List<dynamic> dataList = result.data['data'];
          for (final item in dataList) {
            final data = Map<String, dynamic>.from(item as Map);
            final id = data['id']?.toString() ?? '';
            if (id.isNotEmpty && !seenIds.contains(id)) {
              seenIds.add(id);
              data['distanceKm'] = _toDouble(data['distance']) ?? 0.0;
              if (!_isAvailableForDates(data, startDate, endDate)) continue;
              await _populateOwner(data);
              list.add(MachineModel.fromJson(data));
            }
          }
        }
      } catch (e) {
        print('Cloud Function search failed: $e');
      }
    }

    // ── Layer 3: Direct Firestore query ────
    try {
      dynamic snap;
      try {
        snap = await _db.collection('machines').limit(50).get();
      } catch (err) {
        print('Firestore query error suppressed: $err');
      }
      if (snap != null && snap.docs != null) {
        for (final doc in snap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          final id = doc.id;
          if (seenIds.contains(id)) continue;

          final lat = _toDouble(data['latitude'] ?? data['location']?['lat']) ?? latitude;
          final lng = _toDouble(data['longitude'] ?? data['location']?['lng']) ?? longitude;
          final dist = _calculateDistance(latitude, longitude, lat, lng);
          data['distanceKm'] = dist;

          if (!_isAvailableForDates(data, startDate, endDate)) continue;
          seenIds.add(id);
          await _populateOwner(data);
          list.add(MachineModel.fromJson(data));
        }
      }
    } catch (e) {
      print('Firestore query failed: $e');
    }

    // ── Layer 4: Local SharedPreferences Custom Machines ────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final customJsonList = prefs.getStringList('custom_machines') ?? [];
      for (final jsonStr in customJsonList) {
        final data = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
        final id = data['id']?.toString() ?? '';
        if (id.isNotEmpty && !seenIds.contains(id)) {
          final lat = _toDouble(data['latitude']) ?? latitude;
          final lng = _toDouble(data['longitude']) ?? longitude;
          data['distanceKm'] = _calculateDistance(latitude, longitude, lat, lng);
          if (!_isAvailableForDates(data, startDate, endDate)) continue;
          seenIds.add(id);
          await _populateOwner(data);
          list.add(MachineModel.fromJson(data));
        }
      }
    } catch (_) {}

    // ── Layer 5: If database is empty, seed Firestore with backend machines ──
    if (list.isEmpty) {
      await _ensureFirestoreSeeded(latitude, longitude);
      try {
        final snap = await _db.collection('machines').get();
        if (snap.docs.isNotEmpty) {
          for (final doc in snap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            final lat = _toDouble(data['latitude']) ?? latitude;
            final lng = _toDouble(data['longitude']) ?? longitude;
            data['distanceKm'] = _calculateDistance(latitude, longitude, lat, lng);
            await _populateOwner(data);
            list.add(MachineModel.fromJson(data));
          }
        }
      } catch (_) {}
    }

    // ── Layer 6: Offline in-memory seed machines fallback guarantee ──────────
    if (list.isEmpty) {
      for (final seed in _seedMachines) {
        final data = Map<String, dynamic>.from(seed);
        final lat = _toDouble(data['latitude']) ?? latitude;
        final lng = _toDouble(data['longitude']) ?? longitude;
        data['distanceKm'] = _calculateDistance(latitude, longitude, lat, lng);
        list.add(MachineModel.fromJson(data));
      }
    }

    // Sort by distance
    list.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

    // ── Type filter ───────────────────────────────────────────────────────────
    if (type != null && type.trim().isNotEmpty) {
      final cleanType = type.trim().toLowerCase();
      final filtered = list.where((m) {
        final mType = m.type.toLowerCase();
        final mModel = (m.model ?? '').toLowerCase();
        return mType == cleanType || mType.contains(cleanType) ||
            cleanType.contains(mType) || mModel.contains(cleanType);
      }).toList();
      if (filtered.isNotEmpty) return filtered;
    }

    return list;
  }

  Future<void> _ensureFirestoreSeeded(double userLat, double userLng) async {
    for (final seed in _seedMachines) {
      final data = Map<String, dynamic>.from(seed);
      final id = data['id'] as String;
      try {
        data['latitude'] = userLat + (Random().nextDouble() - 0.5) * 0.05;
        data['longitude'] = userLng + (Random().nextDouble() - 0.5) * 0.05;
        await _db.collection('machines').doc(id).set(data);
      } catch (_) {}
    }
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Future<MachineModel> getById(String id) async {
    try {
      dynamic doc;
      try { doc = await _db.collection('machines').doc(id).get(); } catch (_) {}
      if (doc != null && doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        await _populateOwner(data);
        return MachineModel.fromJson(data);
      }
    } catch (_) {}

    // Check local custom machines
    try {
      final prefs = await SharedPreferences.getInstance();
      final customJsonList = prefs.getStringList('custom_machines') ?? [];
      for (final jsonStr in customJsonList) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (data['id'] == id) {
          await _populateOwner(data);
          return MachineModel.fromJson(data);
        }
      }
    } catch (_) {}

    final seedMatch = _seedMachines.firstWhere(
      (m) => m['id'] == id,
      orElse: () => _seedMachines.first,
    );
    final data = Map<String, dynamic>.from(seedMatch);
    await _populateOwner(data);
    return MachineModel.fromJson(data);
  }

  Future<void> _populateOwner(Map<String, dynamic> data) async {
    if (data['owner'] != null && data['owner'] is Map<String, dynamic>) {
      final ownerMap = Map<String, dynamic>.from(data['owner'] as Map);
      ownerMap['id'] ??= data['ownerId'] ?? data['owner_id'] ?? data['userId'] ?? 'owner_id';
      data['owner'] = ownerMap;
      return;
    }

    final String? ownerId = (data['ownerId'] ?? data['owner_id'] ?? data['userId'] ?? data['user_id'])?.toString();
    if (ownerId != null && ownerId.isNotEmpty) {
      try {
        dynamic ownerDoc;
        try { ownerDoc = await _db.collection('users').doc(ownerId).get(); } catch (_) {}
        if (ownerDoc != null && ownerDoc.exists && ownerDoc.data() != null) {
          final ownerData = Map<String, dynamic>.from(ownerDoc.data()!);
          ownerData['id'] = ownerDoc.id;
          data['owner'] = ownerData;
          return;
        }
      } catch (_) {}
    }

    final ownerName = (data['ownerName'] ?? data['owner_name'] ?? data['contactName'] ?? '').toString();
    final ownerPhone = (data['ownerPhone'] ?? data['owner_phone'] ?? data['phone'] ?? data['mobile'] ?? data['contactPhone'] ?? '').toString();

    data['owner'] = {
      'id': ownerId ?? 'owner_default',
      'name': ownerName.isNotEmpty ? ownerName : 'உரிமையாளர் / Machine Owner',
      'phone': ownerPhone.isNotEmpty ? ownerPhone : '+91 98765 43210',
      'role': 'owner',
      'preferredLanguage': 'ta',
      'kycStatus': 'verified',
    };
  }

  Future<List<MachineModel>> getMyMachines() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return [];

    final userData = jsonDecode(userJson) as Map<String, dynamic>;
    final ownerId = userData['id'] as String;

    final List<MachineModel> list = [];

    try {
      dynamic snap;
      try { snap = await _db.collection('machines').where('ownerId', isEqualTo: ownerId).get(); } catch (_) {}
      if (snap != null && snap.docs != null) {
        for (final doc in snap.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['owner'] = userData;
          list.add(MachineModel.fromJson(data));
        }
      }
    } catch (_) {}

    try {
      final customJsonList = prefs.getStringList('custom_machines') ?? [];
      for (final jsonStr in customJsonList) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (data['ownerId'] == ownerId && !list.any((m) => m.id == data['id'])) {
          data['owner'] = userData;
          list.add(MachineModel.fromJson(data));
        }
      }
    } catch (_) {}

    return list;
  }

  Future<MachineModel> create({
    required String type,
    String? model,
    double? pricePerHour,
    double? pricePerAcre,
    bool operatorIncluded = false,
    required double latitude,
    required double longitude,
    String? village,
    String? district,
    double serviceRadiusKm = 20,
    List<String> photos = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) throw Exception('Unauthorized');

    final userData = jsonDecode(userJson) as Map<String, dynamic>;
    final ownerId = userData['id'] as String;

    final id = _db.collection('machines').doc().id;

    final geoFirePoint = GeoFirePoint(GeoPoint(latitude, longitude));

    final machineData = {
      'id': id,
      'type': type,
      if (model != null) 'model': model,
      if (pricePerHour != null) 'pricePerHour': pricePerHour,
      if (pricePerAcre != null) 'pricePerAcre': pricePerAcre,
      'operatorIncluded': operatorIncluded,
      'status': 'active',
      'latitude': latitude,
      'longitude': longitude,
      'village': village,
      'district': district,
      'location': {
        'geohash': geoFirePoint.geohash,
        'lat': latitude,
        'lng': longitude,
      },
      'serviceRadius': serviceRadiusKm,
      'serviceRadiusKm': serviceRadiusKm,
      'photos': photos,
      'ownerId': ownerId,
      'ownerName': userData['name'],
      'ownerPhone': userData['phone'],
      'owner': userData,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Save to Firebase Firestore collection 'machines'
    try {
      final firestoreData = Map<String, dynamic>.from(machineData);
      firestoreData['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('machines').doc(id).set(firestoreData);
    } catch (_) {}

    // Save locally so created machine persists immediately
    try {
      final customJsonList = prefs.getStringList('custom_machines') ?? [];
      customJsonList.add(jsonEncode(machineData));
      await prefs.setStringList('custom_machines', customJsonList);
    } catch (_) {}

    return MachineModel.fromJson(machineData);
  }

  Future<MachineModel> update(String id, Map<String, dynamic> fields) async {
    await _db.collection('machines').doc(id).update(fields);
    return getById(id);
  }

  Future<void> blockAvailability(String id, DateTime start, DateTime end) async {
    await _db.collection('machines').doc(id).update({
      'blockedDates': FieldValue.arrayUnion([
        {
          'startDate': _dateOnly(start),
          'endDate': _dateOnly(end),
        }
      ])
    });
  }

  String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
