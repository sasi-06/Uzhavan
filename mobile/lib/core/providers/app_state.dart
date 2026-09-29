import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/booking_repository.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  final ApiClient api = ApiClient();
  late final AuthRepository authRepo = AuthRepository(api);
  late final MachineRepository machineRepo = MachineRepository(api);
  late final BookingRepository bookingRepo = BookingRepository(api);

  UserModel? _user;
  bool _loading = true;
  String _activeRole = 'farmer'; // 'farmer' or 'owner'
  int _consecutiveVoiceFailures = 0;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  String get activeRole => _activeRole;
  int get consecutiveVoiceFailures => _consecutiveVoiceFailures;

  String? _voiceSearchFilter;
  String? get voiceSearchFilter => _voiceSearchFilter;

  void setVoiceSearchFilter(String? type) {
    _voiceSearchFilter = type;
    notifyListeners();
  }

  double latitude = 13.0827;
  double longitude = 80.2707;
  String? village;
  String? district;

  void setLocation(double lat, double lng, {String? v, String? d}) {
    latitude = lat;
    longitude = lng;
    village = v;
    district = d;
    notifyListeners();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');
    final savedRole = prefs.getString('active_role');

    if (token != null && userJson != null) {
      api.setToken(token);
      _user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _activeRole = savedRole ?? (_user?.role == 'owner' ? 'owner' : 'farmer');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> setActiveRole(String role) async {
    if (role != 'farmer' && role != 'owner') return;
    _activeRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_role', role);
    notifyListeners();
  }

  void recordVoiceFailure() {
    _consecutiveVoiceFailures++;
    notifyListeners();
  }

  void resetVoiceFailures() {
    _consecutiveVoiceFailures = 0;
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (_user == null) return;
    final updatedUser = UserModel(
      id: _user!.id,
      name: _user!.name,
      phone: _user!.phone,
      role: _user!.role,
      preferredLanguage: langCode,
      kycStatus: _user!.kycStatus,
    );
    await _saveSession(api.token ?? '', updatedUser);
  }

  Future<void> _saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode({
      'id': user.id,
      'name': user.name,
      'phone': user.phone,
      'role': user.role,
      'preferredLanguage': user.preferredLanguage,
      'kycStatus': user.kycStatus,
    }));
    api.setToken(token);
    _user = user;
    if (prefs.getString('active_role') == null) {
      _activeRole = user.role == 'owner' ? 'owner' : 'farmer';
    }
    notifyListeners();
  }

  Future<String?> sendOtp(String phone) => authRepo.sendOtp(phone);

  Future<void> register({
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
    final res = await authRepo.register(
      phone: phone,
      otp: otp,
      name: name,
      role: role,
      preferredLanguage: preferredLanguage,
      password: password,
      village: village,
      district: district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
    await _saveSession(res.token, res.user);
  }

  Future<void> login({required String phone, required String otp}) async {
    final res = await authRepo.verifyOtp(phone: phone, otp: otp);
    await _saveSession(res.token, res.user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('active_role');
    api.setToken(null);
    _user = null;
    _activeRole = 'farmer';
    notifyListeners();
  }

  Future<void> updateUserEmergencyContact({
    required String name,
    required String phone,
    required String relation,
  }) async {
    if (_user == null) return;
    final updatedData = {
      'emergencyName': name,
      'emergencyPhone': phone,
      'emergencyRelation': relation,
    };
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.id).update(updatedData);
    } catch (_) {}

    // Update local session
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final userJsonMap = jsonDecode(userJson) as Map<String, dynamic>;
      userJsonMap.addAll(updatedData);
      final updatedUser = UserModel.fromJson(userJsonMap);
      await _saveSession(_user!.id, updatedUser);
    }
  }
}
