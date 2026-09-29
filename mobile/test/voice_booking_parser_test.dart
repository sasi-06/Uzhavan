/// Unit tests for VoiceBookingParser — run with:
///   flutter test test/voice_booking_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:uzhavan/core/services/voice_booking_parser.dart';
import 'package:uzhavan/core/models/voice_booking_request.dart';

void main() {
  group('VoiceBookingParser — Machine Type', () {
    test('detects tractor in English', () {
      final r = VoiceBookingParser.tryParse('I want a tractor for ploughing', 'en');
      expect(r, isNotNull);
      expect(r!.machineType, VoiceBookingMachineType.tractor);
    });

    test('detects tractor in Tamil', () {
      final r = VoiceBookingParser.tryParse('டிராக்டர் வேண்டும்', 'ta');
      expect(r, isNotNull);
      expect(r!.machineType, VoiceBookingMachineType.tractor);
    });

    test('detects tractor in Tanglish', () {
      final r = VoiceBookingParser.tryParse('tractor vennum 2 acre', 'ta');
      expect(r, isNotNull);
      expect(r!.machineType, VoiceBookingMachineType.tractor);
    });

    test('detects harvester', () {
      final r = VoiceBookingParser.tryParse('harvester for 5 acres', 'en');
      expect(r, isNotNull);
      expect(r!.machineType, VoiceBookingMachineType.harvester);
    });

    test('detects rotavator in Tamil', () {
      final r = VoiceBookingParser.tryParse('ரோட்டவேட்டர் வேண்டும் 3 ஏக்கர்', 'ta');
      expect(r, isNotNull);
      expect(r!.machineType, VoiceBookingMachineType.rotavator);
    });

    test('returns null for unknown machine', () {
      final r = VoiceBookingParser.tryParse('hello how are you', 'en');
      expect(r, isNull);
    });
  });

  group('VoiceBookingParser — Area Extraction', () {
    test('extracts numeric area', () {
      final r = VoiceBookingParser.tryParse('tractor for 2 acres ploughing', 'en');
      expect(r?.areaAcres, 2.0);
    });

    test('extracts decimal area', () {
      final r = VoiceBookingParser.tryParse('tractor 2.5 acres', 'en');
      expect(r?.areaAcres, 2.5);
    });

    test('extracts Tamil word-number இரண்டு=2', () {
      final r = VoiceBookingParser.tryParse('டிராக்டர் இரண்டு ஏக்கர்', 'ta');
      expect(r?.areaAcres, 2.0);
    });

    test('extracts Tamil word-number ஐந்து=5', () {
      final r = VoiceBookingParser.tryParse('harvester ஐந்து ஏக்கர்', 'ta');
      expect(r?.areaAcres, 5.0);
    });

    test('extracts English word-number three=3', () {
      final r = VoiceBookingParser.tryParse('tractor three acres', 'en');
      expect(r?.areaAcres, 3.0);
    });

    test('defaults to 1 acre if no area mentioned', () {
      final r = VoiceBookingParser.tryParse('tractor vennum ploughing', 'ta');
      expect(r?.areaAcres, 1.0);
    });
  });

  group('VoiceBookingParser — Task Extraction', () {
    test('extracts plough task', () {
      final r = VoiceBookingParser.tryParse('tractor for ploughing 2 acres', 'en');
      expect(r?.task, VoiceBookingTask.plough);
    });

    test('extracts harvest task', () {
      final r = VoiceBookingParser.tryParse('harvester for 3 acres', 'en');
      expect(r?.task, VoiceBookingTask.harvest);
    });

    test('extracts sow task in Tamil', () {
      final r = VoiceBookingParser.tryParse('tractor விதைப்பு 2 ஏக்கர்', 'ta');
      expect(r?.task, VoiceBookingTask.sow);
    });

    test('infers plough from rotavator machine type', () {
      final r = VoiceBookingParser.tryParse('rotavator 2 acres', 'en');
      expect(r?.task, VoiceBookingTask.plough);
    });
  });

  group('VoiceBookingParser — Date Extraction', () {
    test('extracts today', () {
      final r = VoiceBookingParser.tryParse('tractor 2 acres today', 'en');
      final today = DateTime.now();
      expect(r?.preferredDate.day, today.day);
    });

    test('extracts tomorrow', () {
      final r = VoiceBookingParser.tryParse('tractor 2 acres tomorrow', 'en');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(r?.preferredDate.day, tomorrow.day);
    });

    test('extracts நாளை as tomorrow', () {
      final r = VoiceBookingParser.tryParse('டிராக்டர் வேண்டும் நாளை', 'ta');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(r?.preferredDate.day, tomorrow.day);
    });

    test('defaults to tomorrow when no date specified', () {
      final r = VoiceBookingParser.tryParse('tractor 2 acres ploughing', 'en');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(r?.preferredDate.day, tomorrow.day);
    });
  });

  group('VoiceBookingParser — Labels', () {
    test('Tamil tractor label', () {
      final r = VoiceBookingParser.tryParse('tractor 2 acres', 'ta');
      expect(r?.machineLabel, contains('டிராக்டர்'));
    });

    test('Tamil date label for tomorrow', () {
      final r = VoiceBookingParser.tryParse('tractor 2 acres tomorrow', 'ta');
      expect(r?.dateLabel, contains('நாளை'));
    });

    test('copyWith updates area', () {
      final r = VoiceBookingParser.tryParse('tractor 2 acres', 'en')!;
      final updated = r.copyWith(areaAcres: 5.0);
      expect(updated.areaAcres, 5.0);
      expect(updated.machineType, r.machineType);
    });
  });
}
