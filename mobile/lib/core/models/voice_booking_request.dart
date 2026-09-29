/// Uzhavan — Voice Booking Request Model
/// Parsed result from a farmer's natural language speech.

enum VoiceBookingMachineType {
  tractor,
  harvester,
  rotavator,
  plough,
  seeder,
  sprayer,
  cultivator,
  unknown,
}

enum VoiceBookingTask {
  plough,
  harvest,
  sow,
  spray,
  cultivate,
  general,
}

class VoiceBookingRequest {
  VoiceBookingRequest({
    required this.originalSpeech,
    required this.machineType,
    required this.machineTypeString,
    required this.task,
    required this.areaAcres,
    required this.preferredDate,
    required this.lang,
  });

  /// The raw STT text from the farmer
  final String originalSpeech;

  /// Parsed machine type enum
  final VoiceBookingMachineType machineType;

  /// Machine type as a lowercase string for repository queries (e.g. "tractor")
  final String machineTypeString;

  /// The farming task inferred from speech
  final VoiceBookingTask task;

  /// How many acres the farmer needs the machine for
  final double areaAcres;

  /// When the farmer wants the machine
  final DateTime preferredDate;

  /// Farmer's preferred language code (ta / te / hi / en)
  final String lang;

  /// Localised task label
  String get taskLabel {
    switch (task) {
      case VoiceBookingTask.plough:
        return lang == 'ta'
            ? 'உழவு / Ploughing'
            : lang == 'te'
                ? 'దున్నడం / Ploughing'
                : lang == 'hi'
                    ? 'जुताई / Ploughing'
                    : 'Ploughing';
      case VoiceBookingTask.harvest:
        return lang == 'ta' ? 'அறுவடை / Harvesting' : 'Harvesting';
      case VoiceBookingTask.sow:
        return lang == 'ta' ? 'விதைப்பு / Sowing' : 'Sowing';
      case VoiceBookingTask.spray:
        return lang == 'ta' ? 'தெளிப்பு / Spraying' : 'Spraying';
      case VoiceBookingTask.cultivate:
        return lang == 'ta' ? 'பயிர் செய்கை / Cultivation' : 'Cultivation';
      default:
        return lang == 'ta' ? 'பொது / General' : 'General';
    }
  }

  /// Localised machine type label
  String get machineLabel {
    switch (machineType) {
      case VoiceBookingMachineType.tractor:
        return lang == 'ta'
            ? 'டிராக்டர் / Tractor'
            : lang == 'hi'
                ? 'ट्रैक्टर / Tractor'
                : lang == 'te'
                    ? 'ట్రాక్టర్ / Tractor'
                    : 'Tractor';
      case VoiceBookingMachineType.harvester:
        return lang == 'ta' ? 'அறுவடை எந்திரம் / Harvester' : 'Harvester';
      case VoiceBookingMachineType.rotavator:
        return lang == 'ta' ? 'ரோட்டவேட்டர் / Rotavator' : 'Rotavator';
      case VoiceBookingMachineType.plough:
        return lang == 'ta' ? 'கலப்பை / Plough' : 'Plough';
      case VoiceBookingMachineType.seeder:
        return lang == 'ta' ? 'விதைப்பான் / Seeder' : 'Seeder';
      case VoiceBookingMachineType.sprayer:
        return lang == 'ta' ? 'தெளிப்பான் / Sprayer' : 'Sprayer';
      default:
        return lang == 'ta' ? 'எந்திரம் / Machine' : 'Machine';
    }
  }

  /// Short date label e.g. "நாளை / Tomorrow" or "12/9"
  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(preferredDate.year, preferredDate.month, preferredDate.day);

    if (d == today) return lang == 'ta' ? 'இன்று / Today' : 'Today';
    if (d == today.add(const Duration(days: 1))) {
      return lang == 'ta' ? 'நாளை / Tomorrow' : 'Tomorrow';
    }
    return '${preferredDate.day}/${preferredDate.month}/${preferredDate.year}';
  }

  /// Creates a copy with updated fields for the verification step
  VoiceBookingRequest copyWith({
    double? areaAcres,
    DateTime? preferredDate,
  }) {
    return VoiceBookingRequest(
      originalSpeech: originalSpeech,
      machineType: machineType,
      machineTypeString: machineTypeString,
      task: task,
      areaAcres: areaAcres ?? this.areaAcres,
      preferredDate: preferredDate ?? this.preferredDate,
      lang: lang,
    );
  }
}
