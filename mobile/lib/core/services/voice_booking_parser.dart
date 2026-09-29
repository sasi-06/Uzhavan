/// Uzhavan — Voice Booking NLU Parser
///
/// Extracts machine type, area, task, and date from free-form speech.
/// Supports Tamil, Tanglish, Telugu, Hindi, and English.

import '../models/voice_booking_request.dart';

class VoiceBookingParser {
  VoiceBookingParser._();

  /// Attempts to parse a natural language booking request.
  /// Returns null if no machine type could be identified.
  static VoiceBookingRequest? tryParse(String speech, String lang) {
    final text = speech.toLowerCase().trim();
    if (text.isEmpty) return null;

    final machineType = _extractMachineType(text);
    if (machineType == VoiceBookingMachineType.unknown) return null;

    return VoiceBookingRequest(
      originalSpeech: speech,
      machineType: machineType,
      machineTypeString: _machineTypeToString(machineType),
      task: _extractTask(text, machineType),
      areaAcres: _extractArea(text),
      preferredDate: _extractDate(text),
      lang: lang,
    );
  }

  // ── Machine type detection ──────────────────────────────────────────────────

  static VoiceBookingMachineType _extractMachineType(String text) {
    // Tractor
    if (_any(text, [
      'tractor', 'டிராக்டர்', 'ट्रैक्टर', 'ट्रेक्टर', 'ట్రాక్టర్',
      'traktor', 'tracter', 'டிராக்டர', 'tractor vennum', 'டிராக்டர் வேண்டும்',
    ])) return VoiceBookingMachineType.tractor;

    // Harvester
    if (_any(text, [
      'harvester', 'அறுவடை எந்திரம்', 'அறுவடை', 'harvest machine',
      'harvesting machine', 'హార్వెస్టర్', 'हार्वेस्टर', 'combine harvester',
    ])) return VoiceBookingMachineType.harvester;

    // Rotavator
    if (_any(text, [
      'rotavator', 'ரோட்டவேட்டர்', 'rotavater', 'rotovator', 'rotivator',
      'రోటావేటర్', 'रोटावेटर',
    ])) return VoiceBookingMachineType.rotavator;

    // Plough (implement — maps to tractor with plough task if no other machine)
    if (_any(text, [
      'plough', 'plow', 'கலப்பை', 'ஏர்', 'ploughing', 'plowing',
      'నాగలి', 'हल', 'disc plough',
    ])) return VoiceBookingMachineType.plough;

    // Seeder
    if (_any(text, [
      'seeder', 'seed drill', 'விதைப்பான்', 'விதை', 'sowing machine',
      'విత్తన యంత్రం', 'बीज ड्रिल',
    ])) return VoiceBookingMachineType.seeder;

    // Sprayer
    if (_any(text, [
      'sprayer', 'தெளிப்பான்', 'boom sprayer', 'crop sprayer', 'spray',
      'పంట స్ప్రేయర్', 'स्प्रेयर',
    ])) return VoiceBookingMachineType.sprayer;

    // Cultivator
    if (_any(text, [
      'cultivator', 'உழவு', 'உழ', 'கடைசி உழவு', 'కల్టివేటర్', 'कल्टीवेटर',
    ])) return VoiceBookingMachineType.cultivator;

    return VoiceBookingMachineType.unknown;
  }

  static String _machineTypeToString(VoiceBookingMachineType t) {
    switch (t) {
      case VoiceBookingMachineType.tractor: return 'tractor';
      case VoiceBookingMachineType.harvester: return 'harvester';
      case VoiceBookingMachineType.rotavator: return 'rotavator';
      case VoiceBookingMachineType.plough: return 'plough';
      case VoiceBookingMachineType.seeder: return 'seeder';
      case VoiceBookingMachineType.sprayer: return 'sprayer';
      case VoiceBookingMachineType.cultivator: return 'cultivator';
      default: return 'tractor';
    }
  }

  // ── Task detection ──────────────────────────────────────────────────────────

  static VoiceBookingTask _extractTask(String text, VoiceBookingMachineType machineType) {
    if (_any(text, ['plough', 'plow', 'ploughing', 'உழவு', 'உழ', 'ஏர்', 'కదలింపు', 'जुताई'])) {
      return VoiceBookingTask.plough;
    }
    if (_any(text, ['harvest', 'அறுவடை', 'harvesting', 'కోత', 'कटाई'])) {
      return VoiceBookingTask.harvest;
    }
    if (_any(text, ['sow', 'sowing', 'விதை', 'விதைப்பு', 'seed', 'విత్తు', 'बुवाई'])) {
      return VoiceBookingTask.sow;
    }
    if (_any(text, ['spray', 'spraying', 'தெளி', 'தெளிப்பு', 'పిచికారీ', 'छिड़काव'])) {
      return VoiceBookingTask.spray;
    }
    if (_any(text, ['cultivat', 'பயிர்', 'கடைசி', 'సాగు', 'खेती'])) {
      return VoiceBookingTask.cultivate;
    }
    // Infer from machine type
    switch (machineType) {
      case VoiceBookingMachineType.harvester: return VoiceBookingTask.harvest;
      case VoiceBookingMachineType.seeder: return VoiceBookingTask.sow;
      case VoiceBookingMachineType.sprayer: return VoiceBookingTask.spray;
      case VoiceBookingMachineType.plough:
      case VoiceBookingMachineType.rotavator:
      case VoiceBookingMachineType.cultivator: return VoiceBookingTask.plough;
      default: return VoiceBookingTask.general;
    }
  }

  // ── Area extraction ─────────────────────────────────────────────────────────

  static double _extractArea(String text) {
    // Tamil word-numbers → digit
    final tamilNums = {
      'ஒன்று': 1, 'இரண்டு': 2, 'மூன்று': 3, 'நான்கு': 4,
      'ஐந்து': 5, 'ஆறு': 6, 'ஏழு': 7, 'எட்டு': 8,
      'ஒன்பது': 9, 'பத்து': 10, 'பதினைந்து': 15, 'இருபது': 20,
    };
    // Telugu word-numbers
    final teluguNums = {
      'ఒకటి': 1, 'రెండు': 2, 'మూడు': 3, 'నాలుగు': 4,
      'అయిదు': 5, 'ఆరు': 6, 'ఏడు': 7, 'ఎనిమిది': 8,
      'తొమ్మిది': 9, 'పది': 10,
    };
    // Hindi word-numbers
    final hindiNums = {
      'एक': 1, 'दो': 2, 'तीन': 3, 'चार': 4,
      'पाँच': 5, 'छह': 6, 'सात': 7, 'आठ': 8,
      'नौ': 9, 'दस': 10,
    };
    // English word-numbers
    final engNums = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4,
      'five': 5, 'six': 6, 'seven': 7, 'eight': 8,
      'nine': 9, 'ten': 10, 'fifteen': 15, 'twenty': 20,
    };

    // Try all word-number maps
    for (final map in [tamilNums, teluguNums, hindiNums, engNums]) {
      for (final entry in map.entries) {
        // Word-number followed by area unit
        final areaUnits = ['ஏக்கர்', 'acre', 'acres', 'ఎకరం', 'ఎకరాలు', 'एकड़', 'ek'];
        for (final unit in areaUnits) {
          if (text.contains(entry.key) && text.contains(unit)) {
            return entry.value.toDouble();
          }
        }
      }
    }

    // Numeric extraction: look for "N acre/ஏக்கர்" pattern
    final patterns = [
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:ஏக்கர்|acre|acres|ఎకరం|ఎకరాలు|एकड़)', unicode: true),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:ek)', unicode: true),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1)!) ?? 1.0;
      }
    }

    // Default: 1 acre
    return 1.0;
  }

  // ── Date extraction ─────────────────────────────────────────────────────────

  static DateTime _extractDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_any(text, ['today', 'இன்று', 'आज', 'ఈ రోజు'])) {
      return today;
    }
    if (_any(text, [
      'tomorrow', 'நாளை', 'नाल', 'कल', 'రేపు', 'நாளைக்கு',
    ])) {
      return today.add(const Duration(days: 1));
    }
    if (_any(text, ['day after', 'நாளை மறுதினம்', 'நாளை மறுநாள்', 'परसों'])) {
      return today.add(const Duration(days: 2));
    }
    if (_any(text, ['next week', 'அடுத்த வாரம்', 'अगले हफ्ते', 'వచ్చే వారం'])) {
      return today.add(const Duration(days: 7));
    }

    // Weekday names — find next occurrence
    final weekdays = {
      'monday': 1, 'திங்கள்': 1, 'сोमवार': 1,
      'tuesday': 2, 'செவ்வாய்': 2,
      'wednesday': 3, 'புதன்': 3,
      'thursday': 4, 'வியாழன்': 4,
      'friday': 5, 'வெள்ளி': 5,
      'saturday': 6, 'சனி': 6,
      'sunday': 7, 'ஞாயிறு': 7,
    };
    for (final entry in weekdays.entries) {
      if (text.contains(entry.key)) {
        var daysAhead = entry.value - today.weekday;
        if (daysAhead <= 0) daysAhead += 7;
        return today.add(Duration(days: daysAhead));
      }
    }

    // Default: tomorrow
    return today.add(const Duration(days: 1));
  }

  // ── Helper ──────────────────────────────────────────────────────────────────

  static bool _any(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw.toLowerCase()));
}
