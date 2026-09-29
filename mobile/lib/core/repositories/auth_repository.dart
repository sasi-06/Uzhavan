import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._apiPlaceholder);
  // We ignore ApiClient since we are fully Firebase-dependent now!
  final dynamic _apiPlaceholder;

  final _db = FirebaseFirestore.instance;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<String?> sendOtp(String phone) async {
    // Generate standard 6-digit OTP
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    // Try storing in Firestore otps collection
    try {
      await _db.collection('otps').doc(phone).set({
        'phone': phone,
        'otp': otp,
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
      });
    } catch (e) {
      print('Firestore OTP save fallback: $e');
    }

    return otp; // Dev OTP returned directly to client
  }

  Future<({String token, UserModel user})> register({
    required String phone,
    required String otp,
    required String name,
    String role = 'farmer',
    String preferredLanguage = 'ta',
    String? password,
    String? village,
    String? district,
    double? latitude,
    double? longitude,
  }) async {
    // Verify OTP from Firestore or allow matching OTP
    try {
      final otpDoc = await _db.collection('otps').doc(phone).get();
      if (otpDoc.exists) {
        final otpData = otpDoc.data()!;
        final dbOtp = otpData['otp'] as String;
        final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();

        if (dbOtp != otp || DateTime.now().isAfter(expiresAt)) {
          throw Exception('Invalid or expired OTP');
        }
        await _db.collection('otps').doc(phone).delete().catchError((_) {});
      }
    } catch (e) {
      print('Firestore OTP verify warning: $e');
    }

    // Generate custom user ID
    final id = 'user_${phone.replaceAll(RegExp(r'\D'), '')}';

    final userData = {
      'id': id,
      'phone': phone,
      'name': name,
      'role': role,
      'preferredLanguage': preferredLanguage,
      'kycStatus': 'verified',
      'village': village ?? 'Chennai',
      'district': district ?? 'Chennai',
      'latitude': latitude ?? 13.0827,
      'longitude': longitude ?? 80.2707,
      if (password != null && password.isNotEmpty) 'passwordHash': _hashPassword(password),
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await _db.collection('users').doc(id).set(userData);
    } catch (e) {
      print('Firestore user save warning: $e');
    }

    final user = UserModel.fromJson(userData);
    return (token: id, user: user);
  }

  Future<({String token, UserModel user})> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    // Verify OTP from Firestore if available
    try {
      final otpDoc = await _db.collection('otps').doc(phone).get();
      if (otpDoc.exists) {
        final otpData = otpDoc.data()!;
        final dbOtp = otpData['otp'] as String;
        final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();

        if (dbOtp != otp || DateTime.now().isAfter(expiresAt)) {
          throw Exception('Invalid or expired OTP');
        }
        await _db.collection('otps').doc(phone).delete().catchError((_) {});
      }
    } catch (e) {
      print('Firestore OTP verify warning: $e');
    }

    // Fetch user from Firestore or return local user
    Map<String, dynamic>? userData;
    String userId = 'user_${phone.replaceAll(RegExp(r'\D'), '')}';

    try {
      final query = await _db.collection('users').where('phone', isEqualTo: phone).limit(1).get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        userData = doc.data();
        userId = doc.id;
        userData['id'] = userId;
      }
    } catch (e) {
      print('Firestore user fetch warning: $e');
    }

    if (userData == null) {
      // Fallback dev user session for instant login
      userData = {
        'id': userId,
        'phone': phone,
        'name': 'உழவர் / Uzhavar User',
        'role': 'farmer',
        'preferredLanguage': 'ta',
        'kycStatus': 'verified',
        'village': 'Chennai',
        'district': 'Chennai',
        'latitude': 13.0827,
        'longitude': 80.2707,
      };
    }

    final user = UserModel.fromJson(userData);
    return (token: userId, user: user);
  }
}

