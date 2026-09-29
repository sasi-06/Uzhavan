/// Uzhavan — AI Dialogue Engine
/// Multi-turn slot-filling conversation engine for the AI booking agent.
/// Extracts machineType, areaAcres, and preferredDate from free-form voice/text.

import 'package:flutter/foundation.dart';
import '../models/agent_dialogue_state.dart';
import '../models/machine_model.dart';
import 'agent_script.dart';
import 'on_device_nlp_engine.dart';

class AgentDialogueEngine extends ChangeNotifier {
  AgentDialogueEngine({required this.lang});

  String lang;

  AgentDialogueState _state = AgentDialogueState();
  AgentDialogueState get state => _state;

  // ── Machine type keyword map ──────────────────────────────────────────────────
  static const Map<String, List<String>> _machineKeywords = {
    'tractor': [
      'tractor', 'டிராக்டர்', 'ट्रैक्टर', 'ट्रेक्टर', 'ట్రాక్టర్',
      'traktor', 'tracter', 'tractor vennum',
    ],
    'harvester': [
      'harvester', 'அறுவடை', 'harvest', 'హార్వెస్టర్', 'हार्वेस्टर',
      'combine', 'paddy cutter',
    ],
    'sprayer': [
      'sprayer', 'தெளிப்பான்', 'spray', 'స్ప్రేయర్', 'स्प्रेयर',
      'pest', 'pesticide', 'boom spray',
    ],
    'seeder': [
      'seeder', 'விதைப்பான்', 'விதை', 'seed drill', 'సీడర్', 'सीडर',
      'sowing', 'seed',
    ],
    'rotavator': [
      'rotavator', 'ரோட்டவேட்டர்', 'rotovator', 'రోటావేటర్', 'रोटावेटर',
      'tiller', 'rotary',
    ],
    'plough': [
      'plough', 'plow', 'கலப்பை', 'ஏர்', 'నాగలి', 'हल', 'disc plough',
    ],
  };

  // ── Machine display names ─────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _machineLabels = {
    'tractor':   {'ta': 'டிராக்டர்',   'te': 'ట్రాక్టర్',    'hi': 'ट्रैक्टर',   'en': 'Tractor'},
    'harvester': {'ta': 'அறுவடை எந்திரம்', 'te': 'హార్వెస్టర్', 'hi': 'हार्वेस्टर', 'en': 'Harvester'},
    'sprayer':   {'ta': 'தெளிப்பான்',  'te': 'స్ప్రేయర్',    'hi': 'स्प्रेयर',   'en': 'Sprayer'},
    'seeder':    {'ta': 'விதைப்பான்',   'te': 'సీడర్',        'hi': 'सीडर',       'en': 'Seeder'},
    'rotavator': {'ta': 'ரோட்டவேட்டர்', 'te': 'రోటావేటర్',   'hi': 'रोटावेटर',  'en': 'Rotavator'},
    'plough':    {'ta': 'கலப்பை',       'te': 'నాగలి',        'hi': 'हल',         'en': 'Plough'},
  };

    // ── Quick-reply tap → machine type key ────────────────────────────────────────
  static const Map<String, String> _quickReplyMachineMap = {
    '🚜 டிராக்டர்': 'tractor', '🚜 ట్రాక్టర్': 'tractor',
    '🚜 ट्रैक्टर': 'tractor',  '🚜 Tractor': 'tractor',
    '🌾 அறுவடை': 'harvester',  '🌾 హార్వెస్టర్': 'harvester',
    '🌾 हार्वेस्टर': 'harvester', '🌾 Harvester': 'harvester',
    '💧 தெளிப்பான்': 'sprayer', '💧 స్ప్రేయర్': 'sprayer',
    '💧 स्प्रेयर': 'sprayer',   '💧 Sprayer': 'sprayer',
    '🌱 விதைப்பான்': 'seeder',  '🌱 సీడర్': 'seeder',
    '🌱 सीडर': 'seeder',        '🌱 Seeder': 'seeder',
    '🔄 ரோட்டவேட்டர்': 'rotavator', '🔄 రోటావేటర్': 'rotavator',
    '🔄 रोटावेटर': 'rotavator', '🔄 Rotavator': 'rotavator',
  };

  // ── Quick-reply tap → area acres ─────────────────────────────────────────────
  static final RegExp _areaQuickReply = RegExp(r'^(\d+(?:\.\d+)?)\s*(ஏக்கர்|எகரம்|ఎకరాలు|एकड़|acre|acres)?$');

  // ── Start conversation ────────────────────────────────────────────────────────

  void startConversation() {
    // Preload on-device neural model asynchronously in background
    OnDeviceNlpEngine.instance.loadModel();

    final greeting = AgentMessage(
      text: AgentScript.greeting(lang),
      isAgent: true,
      quickReplies: AgentScript.machineTypeOptions(lang),
      timestamp: DateTime.now(),
    );
    _state = AgentDialogueState(
      currentStep: DialogueStep.askMachineType,
      messages: [greeting],
    );
    notifyListeners();
  }

  // ── Process user input ────────────────────────────────────────────────────────

  /// Called when farmer speaks or taps a quick reply.
  /// Returns the TTS text to speak aloud (the agent's next reply).
  String processInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    // Add farmer message to chat
    _addFarmerMessage(trimmed);

    // ── On-Device Neural NLP Inference ──────────────────────────────────────────
    final prediction = OnDeviceNlpEngine.instance.predict(trimmed);
    final String? badge = (prediction.isNeural && prediction.confidence >= 0.70)
        ? '⚡ On-Device AI • ${(prediction.confidence * 100).toInt()}%'
        : null;

    // Check cancellation intent
    if (prediction.intent == 'cancel_booking') {
      final msg = AgentScript.cancelled(lang);
      _state = _state.copyWith(
        currentStep: DialogueStep.askMachineType,
        machineType: null,
        machineTypeDisplay: null,
        areaAcres: null,
        preferredDate: null,
        selectedOwner: null,
        availableOwners: [],
      );
      _addAgentMessage(msg, quickReplies: AgentScript.machineTypeOptions(lang), aiBadge: badge);
      return msg;
    }

    // ── One-Shot Multi-Slot Extraction ──
    // e.g. "டிராக்டர் வேண்டும் 3 ஏக்கருக்கு நாளை" -> all 3 slots filled in one go!
    if (_state.currentStep == DialogueStep.askMachineType || _state.currentStep == DialogueStep.greet) {
      if (prediction.machineType != null && prediction.areaAcres != null && prediction.preferredDate != null) {
        final machineKey = prediction.machineType!;
        final displayName = _machineLabels[machineKey]?[lang] ?? machineKey;
        _state = _state.copyWith(
          machineType: machineKey,
          machineTypeDisplay: displayName,
          areaAcres: prediction.areaAcres,
          preferredDate: prediction.preferredDate,
          currentStep: DialogueStep.searchingOwners,
        );
        final msg = AgentScript.searching(lang);
        _addAgentMessage(msg, aiBadge: badge);
        return msg;
      }
    }

    switch (_state.currentStep) {
      case DialogueStep.askMachineType:
        return _handleMachineType(trimmed, prediction: prediction, badge: badge);
      case DialogueStep.askArea:
        return _handleArea(trimmed, prediction: prediction, badge: badge);
      case DialogueStep.askDate:
        return _handleDate(trimmed, prediction: prediction, badge: badge);
      case DialogueStep.showOwners:
        return _handleOwnerSelect(trimmed, prediction: prediction, badge: badge);
      case DialogueStep.confirmBooking:
        return _handleConfirm(trimmed, prediction: prediction, badge: badge);
      default:
        return '';
    }
  }

  String _handleMachineType(String input, {NlpPrediction? prediction, String? badge}) {
    final lower = input.toLowerCase();

    // Check on-device prediction first
    String? machineKey = prediction?.machineType;

    // Check quick reply map
    machineKey ??= _quickReplyMachineMap[input];

    // Then check keyword matching
    if (machineKey == null) {
      for (final entry in _machineKeywords.entries) {
        if (entry.value.any((kw) => lower.contains(kw.toLowerCase()))) {
          machineKey = entry.key;
          break;
        }
      }
    }

    if (machineKey == null) {
      final msg = AgentScript.clarify(lang);
      _addAgentMessage(msg, quickReplies: AgentScript.machineTypeOptions(lang));
      return msg;
    }

    final displayName = _machineLabels[machineKey]?[lang] ?? machineKey;
    _state = _state.copyWith(
      machineType: machineKey,
      machineTypeDisplay: displayName,
      currentStep: DialogueStep.askArea,
    );

    final msg = AgentScript.askArea(lang, displayName);
    _addAgentMessage(msg, quickReplies: AgentScript.areaOptions(lang), aiBadge: badge);
    return msg;
  }

  String _handleArea(String input, {NlpPrediction? prediction, String? badge}) {
    double? acres = prediction?.areaAcres;

    // Quick reply match: "3 ஏக்கர்"
    if (acres == null) {
      final qMatch = _areaQuickReply.firstMatch(input.trim());
      if (qMatch != null) {
        acres = double.tryParse(qMatch.group(1) ?? '');
      }
    }

    // Digit extraction from free speech: "மூணு ஏக்கர்", "3 acres"
    if (acres == null) {
      final wordNums = {
        'ஒன்று': 1, 'ஒரு': 1, 'one': 1,
        'இரண்டு': 2, 'two': 2, 'రెండు': 2,
        'மூன்று': 3, 'மூணு': 3, 'three': 3, 'మూడు': 3, 'तीन': 3,
        'நான்கு': 4, 'four': 4, 'నాలుగు': 4, 'चार': 4,
        'ஐந்து': 5, 'five': 5, 'ఐదు': 5, 'पाँच': 5,
        'ஆறு': 6, 'six': 6, 'ఆరు': 6, 'छह': 6,
        'ஏழு': 7, 'seven': 7, 'ఏడు': 7, 'सात': 7,
        'எட்டு': 8, 'eight': 8, 'ఎనిమిది': 8, 'आठ': 8,
        'ஒன்பது': 9, 'nine': 9, 'తొమ్మిది': 9, 'नौ': 9,
        'பத்து': 10, 'ten': 10, 'పది': 10, 'दस': 10,
      };
      final lower = input.toLowerCase();
      for (final e in wordNums.entries) {
        if (lower.contains(e.key)) {
          acres = e.value.toDouble();
          break;
        }
      }
    }

    // Numeric extraction
    if (acres == null) {
      final match = RegExp(r'\b(\d+(?:\.\d+)?)\b').firstMatch(input);
      if (match != null) acres = double.tryParse(match.group(1) ?? '');
    }

    if (acres == null || acres <= 0) {
      final msg = AgentScript.clarify(lang);
      _addAgentMessage(msg, quickReplies: AgentScript.areaOptions(lang));
      return msg;
    }

    _state = _state.copyWith(areaAcres: acres, currentStep: DialogueStep.askDate);
    final msg = AgentScript.askDate(lang);
    _addAgentMessage(msg, quickReplies: AgentScript.dateOptions(lang), aiBadge: badge);
    return msg;
  }

  String _handleDate(String input, {NlpPrediction? prediction, String? badge}) {
    final lower = input.toLowerCase();
    DateTime? date = prediction?.preferredDate;
    final today = DateTime.now();

    if (date == null) {
      // Quick reply or keyword match
      if (_containsAny(lower, ['இன்று', 'today', 'ఈ రోజు', 'आज'])) {
        date = today;
      } else if (_containsAny(lower, ['நாளை', 'tomorrow', 'రేపు', 'कल'])) {
        date = today.add(const Duration(days: 1));
      } else if (_containsAny(lower, ['2 நாள்', '2 days', '2 రోజుల', '2 दिन', 'two days'])) {
        date = today.add(const Duration(days: 2));
      } else if (_containsAny(lower, ['வாரம்', 'week', 'వారం', 'हफ्ते', 'this week'])) {
        date = today.add(const Duration(days: 3));
      } else {
        // Try to extract a number as "in N days"
        final match = RegExp(r'\b(\d+)\b').firstMatch(input);
        if (match != null) {
          final days = int.tryParse(match.group(1) ?? '');
          if (days != null && days > 0 && days <= 30) {
            date = today.add(Duration(days: days));
          }
        }
      }
    }

    if (date == null) {
      final msg = AgentScript.clarify(lang);
      _addAgentMessage(msg, quickReplies: AgentScript.dateOptions(lang));
      return msg;
    }

    _state = _state.copyWith(
      preferredDate: date,
      currentStep: DialogueStep.searchingOwners,
    );

    final msg = AgentScript.searching(lang);
    _addAgentMessage(msg, aiBadge: badge);
    return msg;
  }

  /// Called after machine search completes with results
  void setOwnerResults(List<MachineModel> owners) {
    if (owners.isEmpty) {
      final msg = AgentScript.noOwnersFound(lang);
      _state = _state.copyWith(
        availableOwners: [],
        currentStep: DialogueStep.askMachineType,
        isSearching: false,
      );
      _addAgentMessage(msg, quickReplies: AgentScript.machineTypeOptions(lang));
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      availableOwners: owners,
      currentStep: DialogueStep.showOwners,
      isSearching: false,
    );

    // Build announcement message
    final count = owners.length;
    final display = _state.machineTypeDisplay ?? _state.machineType ?? '';
    var msg = AgentScript.ownersFound(lang, count, display);

    // Announce top 3 owners
    final top = owners.take(3).toList();
    final buffer = StringBuffer(msg);
    for (var i = 0; i < top.length; i++) {
      final o = top[i];
      buffer.write(' ');
      buffer.write(AgentScript.announceOwner(
        lang, i + 1,
        o.owner?.name ?? 'உரிமையாளர்',
        o.distanceKm,
        o.displayPrice,
      ));
    }
    msg = buffer.toString();

    _addAgentMessage(msg);
    notifyListeners();
  }

  String _handleOwnerSelect(String input, {NlpPrediction? prediction, String? badge}) {
    final lower = input.toLowerCase();
    final owners = _state.availableOwners;
    MachineModel? selected;

    // Number selection from on-device prediction or text
    int? idx = prediction?.ownerIndex;
    if (idx == null) {
      if (_containsAny(lower, ['முதல்', 'first', '1', 'one', 'మొదటి', 'पहला'])) idx = 0;
      else if (_containsAny(lower, ['இரண்டாவது', 'second', '2', 'రెండవ', 'दूसरा'])) idx = 1;
      else if (_containsAny(lower, ['மூன்றாவது', 'third', '3', 'మూడవ', 'तीसरा'])) idx = 2;
    }

    if (idx != null && idx < owners.length) {
      selected = owners[idx];
    } else {
      // Name matching
      for (final o in owners) {
        final name = (o.owner?.name ?? '').toLowerCase();
        if (name.split('/').any((part) => lower.contains(part.trim().toLowerCase()))) {
          selected = o;
          break;
        }
      }
    }

    if (selected == null) {
      final msg = AgentScript.clarify(lang);
      _addAgentMessage(msg);
      return msg;
    }

    _state = _state.copyWith(
      selectedOwner: selected,
      currentStep: DialogueStep.confirmBooking,
    );

    final ownerName = selected.owner?.name ?? 'உரிமையாளர்';
    final display = _state.machineTypeDisplay ?? '';
    final msg = AgentScript.confirm(
      lang, ownerName, display, _state.areaAcres, _state.preferredDate,
    );
    _addAgentMessage(msg, quickReplies: AgentScript.confirmOptions(lang), aiBadge: badge);
    return msg;
  }

  String _handleConfirm(String input, {NlpPrediction? prediction, String? badge}) {
    final lower = input.toLowerCase();
    final confirmed = (prediction?.intent == 'confirm_booking') ||
        _containsAny(lower, [
          'ஆம்', 'சரி', 'yes', 'అవును', 'हाँ', 'han', 'ok', 'send', 'அனுப்பு', 'confirm', '✅',
        ]);

    if (!confirmed) {
      final msg = AgentScript.cancelled(lang);
      _state = _state.copyWith(
        currentStep: DialogueStep.askMachineType,
        machineType: null,
        machineTypeDisplay: null,
        areaAcres: null,
        preferredDate: null,
        selectedOwner: null,
        availableOwners: [],
      );
      _addAgentMessage(msg, quickReplies: AgentScript.machineTypeOptions(lang), aiBadge: badge);
      return msg;
    }

    // Trigger broadcast
    final ownerName = _state.selectedOwner?.owner?.name ?? 'உரிமையாளர்';
    _state = _state.copyWith(
      currentStep: DialogueStep.done,
      isBroadcasting: true,
    );
    notifyListeners();

    final msg = AgentScript.done(lang, ownerName);
    _addAgentMessage(msg, aiBadge: badge);
    return msg;
  }

  // ── State helpers ─────────────────────────────────────────────────────────────

  void setSearching(bool v) {
    _state = _state.copyWith(isSearching: v);
    notifyListeners();
  }

  void setBroadcastSent() {
    _state = _state.copyWith(isBroadcasting: false, broadcastSent: true);
    notifyListeners();
  }

  void setListening(bool v) {
    _state = _state.copyWith(isListening: v);
    notifyListeners();
  }

  void reset() {
    _state = AgentDialogueState();
    startConversation();
  }

  void ownerSelectedFromCard(MachineModel owner) {
    _addFarmerMessage(owner.owner?.name ?? owner.type);
    _handleOwnerSelect(owner.owner?.name ?? '1');
    notifyListeners();
  }

  // ── Private chat helpers ──────────────────────────────────────────────────────

  void _addAgentMessage(String text, {List<String> quickReplies = const [], String? aiBadge}) {
    final msg = AgentMessage(
      text: text,
      isAgent: true,
      quickReplies: quickReplies,
      timestamp: DateTime.now(),
      aiBadge: aiBadge,
    );
    _state = _state.copyWith(messages: [..._state.messages, msg]);
    notifyListeners();
  }

  void _addFarmerMessage(String text) {
    final msg = AgentMessage(
      text: text,
      isAgent: false,
      timestamp: DateTime.now(),
    );
    _state = _state.copyWith(messages: [..._state.messages, msg]);
    notifyListeners();
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw.toLowerCase()));
}
