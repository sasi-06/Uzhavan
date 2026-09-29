import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uzhavan/core/repositories/booking_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookingRepository & Seyalil (Active) Flow Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'user': '{"id":"test_owner_01","name":"Owner Test","role":"owner","preferredLanguage":"ta"}',
        'active_role': 'owner',
      });
    });

    test('Initial getMine returns demo booking with pending status', () async {
      final repo = BookingRepository(null);
      final bookings = await repo.getMine();
      expect(bookings.isNotEmpty, isTrue);
      final demo = bookings.firstWhere((b) => b.id == 'b_demo_01');
      expect(demo.status, equals('pending'));
    });

    test('ownerConfirm persists accepted status so getMine returns it on Seyalil page', () async {
      final repo = BookingRepository(null);

      // Confirm (accept) booking
      final confirmed = await repo.ownerConfirm('b_demo_01');
      expect(confirmed.status, equals('accepted'));

      // Simulate next reload (as happens when switching to Seyalil tab)
      final reloaded = await repo.getMine();
      final demo = reloaded.firstWhere((b) => b.id == 'b_demo_01');
      expect(demo.status, equals('accepted'));

      // Check incoming vs active list classification
      final incoming = reloaded.where((b) => b.status == 'pending' || b.status == 'requested' || b.status == 'new').toList();
      final active = reloaded.where((b) => b.status != 'pending' && b.status != 'requested' && b.status != 'new').toList();

      expect(incoming.any((b) => b.id == 'b_demo_01'), isFalse);
      expect(active.any((b) => b.id == 'b_demo_01'), isTrue);
      expect(active.firstWhere((b) => b.id == 'b_demo_01').status, equals('accepted'));
    });

    test('Workflow transitions (confirmed, in_progress, completed) also persist cleanly', () async {
      final repo = BookingRepository(null);

      await repo.updateStatus('b_demo_01', 'confirmed');
      var list = await repo.getMine();
      expect(list.firstWhere((b) => b.id == 'b_demo_01').status, equals('confirmed'));

      await repo.updateStatus('b_demo_01', 'in_progress');
      list = await repo.getMine();
      expect(list.firstWhere((b) => b.id == 'b_demo_01').status, equals('in_progress'));

      await repo.complete('b_demo_01');
      list = await repo.getMine();
      expect(list.firstWhere((b) => b.id == 'b_demo_01').status, equals('completed'));
    });

    test('Farmer updates status when machine taken, and owner immediately sees it', () async {
      // 1. Initially owner accepts request
      final ownerRepo = BookingRepository(null);
      await ownerRepo.ownerConfirm('b_demo_01');

      // 2. Farmer switches context and marks machine as taken (confirmed)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_role', 'farmer');
      final farmerRepo = BookingRepository(null);
      await farmerRepo.updateStatus('b_demo_01', 'confirmed');

      // Verify farmer view shows confirmed
      final farmerBookings = await farmerRepo.getMine();
      expect(farmerBookings.firstWhere((b) => b.id == 'b_demo_01').status, equals('confirmed'));

      // 3. Machine owner checks their bookings — must show confirmed in Seyalil (Active) list!
      await prefs.setString('active_role', 'owner');
      final ownerBookings = await ownerRepo.getMine();
      final ownerActive = ownerBookings.where((b) => b.status != 'pending' && b.status != 'requested' && b.status != 'new').toList();
      expect(ownerActive.firstWhere((b) => b.id == 'b_demo_01').status, equals('confirmed'));
    });
  });
}
