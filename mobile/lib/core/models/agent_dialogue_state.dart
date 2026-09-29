/// Uzhavan — AI Conversational Booking Agent
/// Dialogue slot model — tracks conversation progress and collected data

import '../models/machine_model.dart';

/// The step-by-step conversation stages
enum DialogueStep {
  greet,
  askMachineType,
  askArea,
  askDate,
  searchingOwners,
  showOwners,
  confirmBooking,
  done,
}

/// A single chat message in the conversation
class AgentMessage {
  const AgentMessage({
    required this.text,
    required this.isAgent,
    this.quickReplies = const [],
    this.timestamp,
    this.aiBadge,
  });

  final String text;
  final bool isAgent; // true = AI bubble, false = farmer bubble
  final List<String> quickReplies;
  final DateTime? timestamp;
  final String? aiBadge;
}

/// All collected booking data + conversation state
class AgentDialogueState {
  AgentDialogueState({
    this.currentStep = DialogueStep.greet,
    this.machineType,
    this.machineTypeDisplay,
    this.areaAcres,
    this.preferredDate,
    this.availableOwners = const [],
    this.selectedOwner,
    this.messages = const [],
    this.isListening = false,
    this.isSearching = false,
    this.isBroadcasting = false,
    this.broadcastSent = false,
    this.errorMessage,
  });

  final DialogueStep currentStep;
  final String? machineType;        // e.g. 'tractor'
  final String? machineTypeDisplay; // e.g. 'டிராக்டர்' / 'Tractor'
  final double? areaAcres;
  final DateTime? preferredDate;
  final List<MachineModel> availableOwners;
  final MachineModel? selectedOwner;
  final List<AgentMessage> messages;
  final bool isListening;
  final bool isSearching;
  final bool isBroadcasting;
  final bool broadcastSent;
  final String? errorMessage;

  AgentDialogueState copyWith({
    DialogueStep? currentStep,
    String? machineType,
    String? machineTypeDisplay,
    double? areaAcres,
    DateTime? preferredDate,
    List<MachineModel>? availableOwners,
    MachineModel? selectedOwner,
    List<AgentMessage>? messages,
    bool? isListening,
    bool? isSearching,
    bool? isBroadcasting,
    bool? broadcastSent,
    String? errorMessage,
  }) {
    return AgentDialogueState(
      currentStep: currentStep ?? this.currentStep,
      machineType: machineType ?? this.machineType,
      machineTypeDisplay: machineTypeDisplay ?? this.machineTypeDisplay,
      areaAcres: areaAcres ?? this.areaAcres,
      preferredDate: preferredDate ?? this.preferredDate,
      availableOwners: availableOwners ?? this.availableOwners,
      selectedOwner: selectedOwner ?? this.selectedOwner,
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isSearching: isSearching ?? this.isSearching,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      broadcastSent: broadcastSent ?? this.broadcastSent,
      errorMessage: errorMessage,
    );
  }
}
