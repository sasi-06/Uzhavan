import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

class BookingRepository {
  BookingRepository(this._apiPlaceholder);
  final dynamic _apiPlaceholder;

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<BookingModel> create({
    required String machineId,
    required DateTime startDate,
    required DateTime endDate,
    required double farmerLat,
    required double farmerLng,
    String? farmerVillage,
    double? areaAcres,
    double? hours,
    bool? operatorIncluded,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var userJson = prefs.getString('user');
    if (userJson == null) {
      final defaultUser = {
        'id': 'u_farmer_99',
        'name': 'விவசாயி / Farmer',
        'phone': '9876543210',
        'role': 'farmer',
        'preferredLanguage': 'ta',
      };
      await prefs.setString('user', jsonEncode(defaultUser));
      userJson = jsonEncode(defaultUser);
    }

    final userData = jsonDecode(userJson) as Map<String, dynamic>;
    final renterId = (userData['id'] ?? 'u_farmer_99').toString();

    // ── 0. Check for existing active bookings for the same machine + dates ──
    try {
      final db = _db;
      if (db != null) {
        final existingSnap = await db
            .collection('bookings')
            .where('machineId', isEqualTo: machineId)
            .get()
            .timeout(const Duration(seconds: 5));

        for (final doc in existingSnap.docs) {
          final data = doc.data();
          final status = (data['status'] ?? '').toString().toLowerCase();
          const activeStatuses = {'pending', 'accepted', 'confirmed', 'in_progress'};
          if (!activeStatuses.contains(status)) continue;

          final bookStart = _parseFlexDate(data['startDate']);
          final bookEnd = _parseFlexDate(data['endDate']);
          if (bookStart == null || bookEnd == null) continue;

          if (startDate.isBefore(bookEnd) && endDate.isAfter(bookStart)) {
            throw Exception(
              'இந்த தேதிகளில் எந்திரம் ஏற்கனவே முன்பதிவு செய்யப்பட்டுள்ளது. '
              'வேறு தேதிகளை தேர்ந்தெடுக்கவும். / '
              'Machine is already booked for these dates. Please choose different dates.',
            );
          }
        }
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('already booked')) rethrow;
      debugPrint('Local overlap check failed: $e');
    }

    // Fetch machine details to get pricing and ownerId
    Map<String, dynamic> machineData = {};
    String ownerId = '';
    double? pricePerAcre;
    double? pricePerHour;

    try {
      final db = _db;
      if (db != null) {
        final machineDoc = await db.collection('machines').doc(machineId).get();
        if (machineDoc.exists) {
          machineData = machineDoc.data()!;
          ownerId = (machineData['ownerId'] ?? machineData['owner_id'] ?? machineData['owner']?['id'] ?? '').toString();
          pricePerAcre = _toDouble(machineData['pricePerAcre']);
          pricePerHour = _toDouble(machineData['pricePerHour']);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch machine doc: $e');
    }

    if (ownerId.isEmpty) {
      try {
        final customJsonList = prefs.getStringList('custom_machines') ?? [];
        for (final jsonStr in customJsonList) {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          if (data['id'] == machineId) {
            machineData = data;
            ownerId = (data['ownerId'] ?? data['owner_id'] ?? data['owner']?['id'] ?? '').toString();
            pricePerAcre = _toDouble(data['pricePerAcre']);
            pricePerHour = _toDouble(data['pricePerHour']);
            break;
          }
        }
      } catch (_) {}
    }

    if (ownerId.isEmpty) {
      ownerId = (userData['id'] ?? 'owner_ramesh').toString();
    }

    // Calculate price
    final hoursVal = hours ?? 1.0;
    final acresVal = areaAcres ?? 1.0;
    double priceTotal = 0;
    if (pricePerAcre != null && areaAcres != null) {
      priceTotal = pricePerAcre * acresVal;
    } else if (pricePerHour != null) {
      priceTotal = pricePerHour * hoursVal;
    } else {
      priceTotal = 800.0;
    }

    // Generate booking ID
    final db = _db;
    final bookingId = db != null
        ? db.collection('bookings').doc().id
        : 'b_local_${DateTime.now().millisecondsSinceEpoch}';

    final bookingDoc = {
      'id': bookingId,
      'machineId': machineId,
      'renterId': renterId,
      'ownerId': ownerId,
      'status': 'pending',
      'priceTotal': priceTotal,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'operatorIncluded': operatorIncluded ?? false,
      'farmerLat': farmerLat,
      'farmerLng': farmerLng,
      'farmerVillage': farmerVillage ?? userData['village'] ?? 'Kovilpatti',
      'hoursRequested': hoursVal,
      'areaAcres': acresVal,
      'createdAt': DateTime.now().toIso8601String(),
      'renter': {
        'id': renterId,
        'name': userData['name'] ?? 'விவசாயி / Farmer',
        'phone': userData['phone'] ?? '+91 98765 43210',
        'village': farmerVillage ?? userData['village'] ?? 'Kovilpatti',
        'district': userData['district'] ?? 'Thoothukudi',
      },
      'machine': machineData.isNotEmpty ? machineData : {
        'type': 'tractor',
        'model': 'Mahindra 575 DI (Tractor)',
      },
    };

    // ── 1. Save locally to SharedPreferences FIRST ──────────────────────────
    try {
      final customBookings = prefs.getStringList('custom_bookings') ?? [];
      customBookings.add(jsonEncode(bookingDoc));
      await prefs.setStringList('custom_bookings', customBookings);
    } catch (e) {
      debugPrint('Failed to write local booking: $e');
    }

    // ── 2. Write to Firestore ───────────────────────────────────────────────
    try {
      final firestoreDb = _db;
      if (firestoreDb != null) {
        final firestoreData = Map<String, dynamic>.from(bookingDoc);
        firestoreData['createdAt'] = FieldValue.serverTimestamp();
        try {
          await firestoreDb.collection('bookings').doc(bookingId).set(firestoreData);
        } catch (_) {}
      }
    } catch (_) {}

    return BookingModel.fromJson(bookingDoc);
  }

  static DateTime? _parseFlexDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is Map && v['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
          (v['seconds'] as num).toInt() * 1000);
    }
    try {
      return (v as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> _buildDemoDoc(SharedPreferences prefs, {String? id, String? newStatus}) {
    final userJson = prefs.getString('user');
    final userData = userJson != null
        ? (jsonDecode(userJson) as Map<String, dynamic>)
        : <String, dynamic>{};
    final currentUserId = (userData['id'] ?? '').toString();
    final activeRole = (prefs.getString('active_role') ?? userData['role'] ?? 'owner')
        .toString()
        .toLowerCase();

    final demoOwnerId = activeRole == 'owner'
        ? (currentUserId.isNotEmpty ? currentUserId : 'owner_ramesh')
        : 'owner_ramesh';
    final demoRenterId = activeRole == 'farmer'
        ? (currentUserId.isNotEmpty ? currentUserId : 'user_farmer_demo')
        : 'user_farmer_demo';

    String status = newStatus ?? 'pending';
    if (newStatus == null) {
      final customList = prefs.getStringList('custom_bookings') ?? [];
      for (final s in customList) {
        try {
          final m = jsonDecode(s) as Map;
          if (m['id'] == (id ?? 'b_demo_01') && m['status'] != null) {
            status = m['status'].toString();
            break;
          }
        } catch (_) {}
      }
    }

    return {
      'id': id ?? 'b_demo_01',
      'machineId': 'm_tractor_01',
      'renterId': demoRenterId,
      'ownerId': demoOwnerId,
      'status': status,
      'priceTotal': 1200.0,
      'startDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'operatorIncluded': true,
      'farmerLat': 9.1730,
      'farmerLng': 77.8680,
      'farmerVillage': 'Kovilpatti',
      'hoursRequested': 1.5,
      'areaAcres': 1.0,
      'renter': {
        'id': demoRenterId,
        'name': 'செல்வம் / Farmer Selvam',
        'phone': '+91 97890 56789',
        'village': 'Kovilpatti',
        'district': 'Thoothukudi',
      },
      'machine': {
        'type': 'tractor',
        'model': 'Mahindra 575 DI (45 HP Tractor)',
      },
    };
  }

  Future<List<BookingModel>> getMine() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final userData = userJson != null
        ? (jsonDecode(userJson) as Map<String, dynamic>)
        : <String, dynamic>{};
    final currentUserId = (userData['id'] ?? '').toString();
    final activeRole = (prefs.getString('active_role') ?? userData['role'] ?? 'owner')
        .toString()
        .toLowerCase();
    final isFarmerView = activeRole == 'farmer';

    final List<BookingModel> list = [];
    final Set<String> seenIds = {};

    void processDataMap(Map<String, dynamic> data) {
      final id = (data['id'] ?? '').toString();
      if (id.isEmpty || seenIds.contains(id)) return;

      // Role-based filter
      // For demo booking ('b_demo_01'), always allow it to be visible so owner can accept and test workflow
      if (id != 'b_demo_01' && currentUserId.isNotEmpty) {
        final renterId = (data['renterId'] ?? '').toString();
        final ownerId = (data['ownerId'] ?? '').toString();
        if (isFarmerView && renterId != currentUserId) return;
        if (!isFarmerView && ownerId != currentUserId) return;
      }

      seenIds.add(id);
      try {
        list.add(BookingModel.fromJson(data));
      } catch (e) {
        debugPrint('Booking parse error: $e');
      }
    }

    // ── 1. Load local SharedPreferences custom_bookings FIRST ─────────────
    try {
      final customBookings = prefs.getStringList('custom_bookings') ?? [];
      for (final jsonStr in customBookings) {
        try {
          final data = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
          processDataMap(data);
        } catch (_) {}
      }
    } catch (_) {}

    // ── 2. Query Firestore bookings ──────────────────────────────────────
    try {
      final db = _db;
      if (db != null) {
        dynamic snap;
        try {
          final query = currentUserId.isEmpty
              ? db.collection('bookings')
              : (isFarmerView
                  ? db.collection('bookings').where('renterId', isEqualTo: currentUserId)
                  : db.collection('bookings').where('ownerId', isEqualTo: currentUserId));
          snap = await query.get().timeout(const Duration(seconds: 3));
        } catch (_) {}
        if (snap != null) {
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data() as Map);
              data['id'] = doc.id;
              processDataMap(data);
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // ── 3. Fallback demo request if list is empty ─────────────────────────
    if (list.isEmpty) {
      final demoDoc = _buildDemoDoc(prefs);
      try {
        final customBookings = prefs.getStringList('custom_bookings') ?? [];
        final hasDemo = customBookings.any((s) {
          try {
            return (jsonDecode(s) as Map)['id'] == 'b_demo_01';
          } catch (_) {
            return false;
          }
        });
        if (!hasDemo) {
          customBookings.add(jsonEncode(demoDoc));
          await prefs.setStringList('custom_bookings', customBookings);
        }
      } catch (_) {}

      processDataMap(demoDoc);
    }

    // Sort newest first
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  Future<void> _updateLocalBookingStatus(String id, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customBookings = prefs.getStringList('custom_bookings') ?? [];
      bool found = false;
      final updatedList = <String>[];
      for (final jsonStr in customBookings) {
        try {
          final data = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
          if (data['id'] == id) {
            data['status'] = newStatus;
            found = true;
          }
          updatedList.add(jsonEncode(data));
        } catch (_) {
          updatedList.add(jsonStr);
        }
      }
      if (!found) {
        final demoDoc = _buildDemoDoc(prefs, id: id, newStatus: newStatus);
        updatedList.add(jsonEncode(demoDoc));
      }
      await prefs.setStringList('custom_bookings', updatedList);
    } catch (e) {
      debugPrint('Error updating local booking status: $e');
    }
  }

  Future<BookingModel> getById(String id) async {
    final list = await getMine();
    for (final b in list) {
      if (b.id == id) return b;
    }
    if (list.isNotEmpty) return list.first;
    final prefs = await SharedPreferences.getInstance();
    return BookingModel.fromJson(_buildDemoDoc(prefs, id: id));
  }

  Future<BookingModel> ownerConfirm(String id) async {
    await _updateLocalBookingStatus(id, 'accepted');
    try {
      await _db?.collection('bookings').doc(id).update({'status': 'accepted'});
    } catch (_) {}
    return getById(id);
  }

  Future<BookingModel> updateStatus(String id, String status) async {
    await _updateLocalBookingStatus(id, status);
    try {
      await _db?.collection('bookings').doc(id).update({'status': status});
    } catch (_) {}
    return getById(id);
  }

  Future<BookingModel> cancel(String id) async {
    await _updateLocalBookingStatus(id, 'cancelled');
    try {
      await _db?.collection('bookings').doc(id).update({'status': 'cancelled'});
    } catch (_) {}
    return getById(id);
  }

  Future<BookingModel> complete(String id) async {
    await _updateLocalBookingStatus(id, 'completed');
    try {
      await _db?.collection('bookings').doc(id).update({'status': 'completed'});
    } catch (_) {}
    return getById(id);
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String bookingId,
    required String mode,
  }) async {
    return {
      'paymentId': 'pay_dummy_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'success',
      'mode': mode,
    };
  }
}
