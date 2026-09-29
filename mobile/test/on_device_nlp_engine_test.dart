import 'package:flutter_test/flutter_test.dart';
import 'package:uzhavan/core/services/on_device_nlp_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnDeviceNlpEngine Offline Model Tests', () {
    test('Offline slot extraction extracts machine, area, date without server', () {
      final engine = OnDeviceNlpEngine.instance;

      // 1. One-shot multilingual utterance
      final slots = engine.extractSlots('டிராக்டர் வேண்டும் 3 ஏக்கருக்கு நாளை');
      expect(slots['machineType'], equals('tractor'));
      expect(slots['areaAcres'], equals(3.0));
      expect(slots['preferredDate'], isNotNull);

      // Verify date is tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final extractedDate = slots['preferredDate'] as DateTime;
      expect(extractedDate.day, equals(tomorrow.day));
    });

    test('Offline slot extraction extracts harvester and decimal acres', () {
      final engine = OnDeviceNlpEngine.instance;
      final slots = engine.extractSlots('harvest 2.5 acres today');
      expect(slots['machineType'], equals('harvester'));
      expect(slots['areaAcres'], equals(2.5));
      expect(slots['preferredDate'], isNotNull);
    });

    test('Offline slot extraction extracts Tamil word-numbers (இரண்டு = 2)', () {
      final engine = OnDeviceNlpEngine.instance;
      final slots = engine.extractSlots('ரோட்டவேட்டர் இரண்டு ஏக்கர்');
      expect(slots['machineType'], equals('rotavator'));
      expect(slots['areaAcres'], equals(2.0));
    });

    test('Offline slot extraction extracts Telugu machine and area', () {
      final engine = OnDeviceNlpEngine.instance;
      final slots = engine.extractSlots('ట్రాక్టర్ 5 ఎకరాలు');
      expect(slots['machineType'], equals('tractor'));
      expect(slots['areaAcres'], equals(5.0));
    });

    test('Offline slot extraction extracts Hindi machine and area', () {
      final engine = OnDeviceNlpEngine.instance;
      final slots = engine.extractSlots('ट्रैक्टर 4 एकड़');
      expect(slots['machineType'], equals('tractor'));
      expect(slots['areaAcres'], equals(4.0));
    });

    test('Offline slot extraction extracts owner index selection', () {
      final engine = OnDeviceNlpEngine.instance;
      expect(engine.extractSlots('முதல் நபர்')['ownerIndex'], equals(0));
      expect(engine.extractSlots('second one')['ownerIndex'], equals(1));
      expect(engine.extractSlots('3')['ownerIndex'], equals(2));
    });

    test('Offline heuristic prediction works seamlessly without network', () {
      final engine = OnDeviceNlpEngine.instance;

      final p1 = engine.predict('டிராக்டர் வேண்டும்');
      expect(p1.intent.contains('tractor'), isTrue);
      expect(p1.slots['machineType'], equals('tractor'));

      final p2 = engine.predict('சரி');
      expect(p2.intent, equals('confirm_booking'));

      final p3 = engine.predict('வேண்டாம்');
      expect(p3.intent, equals('cancel_booking'));
    });
  });
}
