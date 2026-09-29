import 'package:flutter_test/flutter_test.dart';
import 'package:uzhavan/core/models/agent_dialogue_state.dart';
import 'package:uzhavan/core/models/machine_model.dart';
import 'package:uzhavan/core/models/user_model.dart';
import 'package:uzhavan/core/services/agent_dialogue_engine.dart';
import 'package:uzhavan/core/services/voice_assistant_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MachineModel> mockOwners = [
    MachineModel(
      id: 'm_tractor_01',
      type: 'tractor',
      status: 'active',
      model: 'Mahindra 575 DI (45 HP Tractor)',
      pricePerHour: 850.0,
      pricePerAcre: 1200.0,
      operatorIncluded: true,
      distanceKm: 3.2,
      owner: UserModel(
        id: 'owner_ramesh',
        name: 'ரமேஷ் குமார் / Ramesh Kumar',
        phone: '+91 98401 23456',
        role: 'owner',
        preferredLanguage: 'ta',
        kycStatus: 'verified',
      ),
    ),
    MachineModel(
      id: 'm_tractor_02',
      type: 'tractor',
      status: 'active',
      model: 'Sonalika International DI 745 III (50 HP)',
      pricePerHour: 900.0,
      pricePerAcre: 1300.0,
      operatorIncluded: true,
      distanceKm: 4.5,
      owner: UserModel(
        id: 'owner_kannan',
        name: 'கண்ணன் வேலு / Kannan Velu',
        phone: '+91 94441 88776',
        role: 'owner',
        preferredLanguage: 'ta',
        kycStatus: 'verified',
      ),
    ),
  ];

  group('Voice Catching Flow — End-to-End Simulation Tests', () {
    test('1. One-Shot Spoken Voice Flow: captures machine, acres, date in 1 sentence', () {
      final engine = AgentDialogueEngine(lang: 'ta');
      engine.startConversation();

      expect(engine.state.currentStep, equals(DialogueStep.askMachineType));

      // Voice recognition catches spoken utterance:
      const caughtSpeech = 'டிராக்டர் வேண்டும் 3 ஏக்கருக்கு நாளை';
      final reply = engine.processInput(caughtSpeech);

      // Verify all 3 slots were caught simultaneously
      expect(engine.state.machineType, equals('tractor'));
      expect(engine.state.areaAcres, equals(3.0));
      expect(engine.state.preferredDate, isNotNull);
      expect(engine.state.currentStep, equals(DialogueStep.searchingOwners));
      expect(reply.contains('உரிமையாளர்களைத் தேடுகிறேன்') || reply.contains('தேடுகிறேன்'), isTrue);

      // Simulate search completed with owners
      engine.setOwnerResults(mockOwners);
      expect(engine.state.currentStep, equals(DialogueStep.showOwners));
      expect(engine.state.availableOwners.length, equals(2));

      // Voice recognition catches owner selection
      const caughtOwnerVoice = 'முதல் நபர்';
      final reply2 = engine.processInput(caughtOwnerVoice);
      expect(engine.state.selectedOwner?.id, equals('m_tractor_01'));
      expect(engine.state.currentStep, equals(DialogueStep.confirmBooking));
      expect(reply2.contains('ரமேஷ் குமார்'), isTrue);

      // Voice recognition catches confirmation
      const caughtConfirmVoice = 'சரி அனுப்பு';
      final reply3 = engine.processInput(caughtConfirmVoice);
      expect(engine.state.currentStep, equals(DialogueStep.done));
      expect(engine.state.isBroadcasting, isTrue);
      expect(reply3.contains('அனுப்பப்பட்டது') || reply3.contains('முடிந்தது'), isTrue);
    });

    test('2. Multi-turn Step-by-step Spoken Voice Catching with Tamil Word-Numbers', () {
      final engine = AgentDialogueEngine(lang: 'ta');
      engine.startConversation();

      // Turn 1: Spoken machine name
      engine.processInput('டிராக்டர்');
      expect(engine.state.machineType, equals('tractor'));
      expect(engine.state.currentStep, equals(DialogueStep.askArea));

      // Turn 2: Spoken Tamil word-number "இரண்டு ஏக்கர்" -> 2.0
      engine.processInput('இரண்டு ஏக்கர்');
      expect(engine.state.areaAcres, equals(2.0));
      expect(engine.state.currentStep, equals(DialogueStep.askDate));

      // Turn 3: Spoken date "நாளைக்கு" -> tomorrow
      engine.processInput('நாளைக்கு');
      expect(engine.state.preferredDate, isNotNull);
      expect(engine.state.currentStep, equals(DialogueStep.searchingOwners));

      // Deliver search results
      engine.setOwnerResults(mockOwners);
      expect(engine.state.currentStep, equals(DialogueStep.showOwners));

      // Turn 4: Spoken "இரண்டாவது" -> 2nd owner
      engine.processInput('இரண்டாவது');
      expect(engine.state.selectedOwner?.id, equals('m_tractor_02'));
      expect(engine.state.currentStep, equals(DialogueStep.confirmBooking));

      // Turn 5: Spoken "ஆம் சரி" -> confirm
      engine.processInput('ஆம் சரி');
      expect(engine.state.currentStep, equals(DialogueStep.done));
      expect(engine.state.isBroadcasting, isTrue);
    });

    test('3. Multilingual Voice Catching: Telugu, Hindi, and English utterances', () {
      // Telugu voice catching
      final engineTe = AgentDialogueEngine(lang: 'te');
      engineTe.startConversation();
      engineTe.processInput('ట్రాక్టర్');
      expect(engineTe.state.machineType, equals('tractor'));

      // Hindi voice catching
      final engineHi = AgentDialogueEngine(lang: 'hi');
      engineHi.startConversation();
      engineHi.processInput('हार्वेस्टर');
      expect(engineHi.state.machineType, equals('harvester'));

      // English voice catching
      final engineEn = AgentDialogueEngine(lang: 'en');
      engineEn.startConversation();
      engineEn.processInput('harvester for 5 acres tomorrow');
      expect(engineEn.state.machineType, equals('harvester'));
      expect(engineEn.state.areaAcres, equals(5.0));
      expect(engineEn.state.currentStep, equals(DialogueStep.searchingOwners));
    });

    test('4. Global Voice Overlay Command Catching (Nav & Agent trigger)', () {
      // Voice catching AI agent invocation
      var res = VoiceAssistantService.parseCommand('உழவன் உதவியாளர்', 'ta');
      expect(res.intent, equals(VoiceIntentType.openAiAgent));

      res = VoiceAssistantService.parseCommand('open ai agent', 'en');
      expect(res.intent, equals(VoiceIntentType.openAiAgent));

      // Voice catching machine search
      res = VoiceAssistantService.parseCommand('டிராக்டர் தேடு', 'ta');
      expect(res.intent, equals(VoiceIntentType.searchMachine));
      expect(res.extractedQuery, equals('டிராக்டர் தேடு'));

      // Voice catching bookings navigation
      res = VoiceAssistantService.parseCommand('என் முன்பதிவுகள்', 'ta');
      expect(res.intent, equals(VoiceIntentType.navigateBookings));

      // Voice catching role switch
      res = VoiceAssistantService.parseCommand('விவசாயி முறைக்கு மாற்று', 'ta');
      expect(res.intent, equals(VoiceIntentType.switchRole));
      expect(res.targetRole, equals('farmer'));
    });

    test('5. Voice Noise / Gibberish Error Shield', () {
      final engine = AgentDialogueEngine(lang: 'ta');
      engine.startConversation();

      // Gibberish spoken voice
      final reply = engine.processInput('xyz blabla unknown sound');
      // Should ask for clarification nicely without crashing
      expect(engine.state.currentStep, equals(DialogueStep.askMachineType));
      expect(engine.state.machineType, isNull);
      expect(reply.isNotEmpty, isTrue);
    });
  });
}
