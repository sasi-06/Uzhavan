// Uzhavan — Booking Broadcaster
// Sends a booking request to Firestore and triggers FCM push notification to the selected owner.

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/machine_model.dart';

class BookingBroadcaster {
  BookingBroadcaster._();
  static final BookingBroadcaster instance = BookingBroadcaster._();

  final _db = FirebaseFirestore.instance;

  /// Broadcasts a booking request to [selectedOwner].
  /// Returns the request ID on success, null on failure.
  Future<String?> broadcastRequest({
    required String farmerId,
    required String farmerName,
    required String farmerPhone,
    required MachineModel selectedOwner,
    required double areaAcres,
    required DateTime preferredDate,
    required String machineType,
    String lang = 'ta',
  }) async {
    final requestId = _generateId();
    final ownerName = selectedOwner.owner?.name ?? 'Owner';
    final ownerId = selectedOwner.owner?.id ?? selectedOwner.id;

    final data = {
      'id': requestId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'machineId': selectedOwner.id,
      'machineType': machineType,
      'machineModel': selectedOwner.model ?? machineType,
      'areaAcres': areaAcres,
      'preferredDate': preferredDate.toIso8601String(),
      'status': 'pending',   // pending → accepted / declined
      'lang': lang,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'ai_agent',  // Tag requests from the AI agent
    };

    try {
      // Write to bookingRequests collection with timeout to avoid hanging when offline
      await _db.collection('bookingRequests').doc(requestId).set(data).timeout(const Duration(seconds: 3));

      // Write a notification entry for the owner (owner's app reads this)
      await _db.collection('ownerNotifications').doc(requestId).set({
        'ownerId': ownerId,
        'requestId': requestId,
        'farmerName': farmerName,
        'machineType': machineType,
        'areaAcres': areaAcres,
        'preferredDate': preferredDate.toIso8601String(),
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 3));

      debugPrint('[Broadcaster] Request $requestId sent to $ownerName');
      return requestId;
    } catch (e) {
      debugPrint('[Broadcaster] Network unavailable/offline: $e. Queuing locally.');
      await _saveOfflineBooking(data);
      return requestId;
    }
  }

  /// Broadcasts to top-N owners simultaneously. First to accept wins.
  Future<String?> broadcastToMany({
    required String farmerId,
    required String farmerName,
    required String farmerPhone,
    required List<MachineModel> owners,
    required double areaAcres,
    required DateTime preferredDate,
    required String machineType,
    String lang = 'ta',
    int maxOwners = 3,
  }) async {
    final requestId = _generateId();
    final top = owners.take(maxOwners).toList();

    final data = {
      'id': requestId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'machineType': machineType,
      'areaAcres': areaAcres,
      'preferredDate': preferredDate.toIso8601String(),
      'status': 'broadcast_pending',
      'broadcastOwners': top.map((o) => o.owner?.id ?? o.id).toList(),
      'lang': lang,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'ai_agent_broadcast',
      'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    };

    try {
      await _db.collection('bookingRequests').doc(requestId).set(data).timeout(const Duration(seconds: 3));

      // Notify all broadcast owners
      final batch = _db.batch();
      for (final owner in top) {
        final notifId = '${requestId}_${owner.owner?.id ?? owner.id}';
        final notifRef = _db.collection('ownerNotifications').doc(notifId);
        batch.set(notifRef, {
          'ownerId': owner.owner?.id ?? owner.id,
          'requestId': requestId,
          'farmerName': farmerName,
          'machineType': machineType,
          'areaAcres': areaAcres,
          'preferredDate': preferredDate.toIso8601String(),
          'status': 'unread',
          'isBroadcast': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit().timeout(const Duration(seconds: 3));

      debugPrint('[Broadcaster] Broadcast $requestId sent to ${top.length} owners');
      return requestId;
    } catch (e) {
      debugPrint('[Broadcaster] Network unavailable/offline broadcast: $e. Queuing locally.');
      await _saveOfflineBooking(data);
      return requestId;
    }
  }

  Future<void> _saveOfflineBooking(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('offline_pending_bookings') ?? [];
      final cleanData = Map<String, dynamic>.from(data);
      cleanData['createdAt'] = DateTime.now().toIso8601String();
      cleanData['isOfflineQueued'] = true;
      list.add(jsonEncode(cleanData));
      await prefs.setStringList('offline_pending_bookings', list);
      debugPrint('[Broadcaster] Saved booking ${data['id']} to offline queue');
    } catch (e) {
      debugPrint('[Broadcaster] Failed to save offline booking: $e');
    }
  }

  /// Stream to watch the booking request status for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRequest(String requestId) {
    return _db.collection('bookingRequests').doc(requestId).snapshots();
  }

  String _generateId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
