import 'package:flutter_test/flutter_test.dart';
import 'package:uzhavan/core/models/agent_dialogue_state.dart';
import 'package:uzhavan/core/models/machine_model.dart';
import 'package:uzhavan/core/models/user_model.dart';
import 'package:uzhavan/core/services/agent_dialogue_engine.dart';
import 'package:uzhavan/core/services/agent_script.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AgentDialogueEngine Multi-turn Dialogue Tests', () {
    test('startConversation initializes state with greeting and machine options', () {
      final engine = AgentDialogueEngine(lang: 'ta');
      engine.startConversation();

      expect(engine.state.currentStep, equals(DialogueStep.askMachineType));
      expect(engine.state.messages.length, equals(1));
      expect(engine.state.messages.first.isAgent, isTrue);
      expect(engine.state.messages.first.quickReplies.isNotEmpty, isTrue);
    });

    test('processInput handles machine selection in Tamil', () {
      final engine = AgentDialogueEngine(lang: 'ta');
      engine.startConversation();

      final reply = engine.processInput('டிராக்டர்');
      expect(reply.isNotEmpty, isTrue);
      expect(engine.state.machineType, equals('tractor'));
      expect(engine.state.currentStep, equals(DialogueStep.askArea));
    });

    test('processInput handles machine selection in English', () {
      final engine = AgentDialogueEngine(lang: 'en');
      engine.startConversation();

      final reply = engine.processInput('tractor');
      expect(reply.isNotEmpty, isTrue);
      expect(engine.state.machineType, equals('tractor'));
      expect(engine.state.currentStep, equals(DialogueStep.askArea));
    });

    test('processInput handles machine selection in Telugu', () {
      final engine = AgentDialogueEngine(lang: 'te');
      engine.startConversation();

      final reply = engine.processInput('ట్రాక్టర్');
      expect(reply.isNotEmpty, isTrue);
      expect(engine.state.machineType, equals('tractor'));
      expect(engine.state.currentStep, equals(DialogueStep.askArea));
    });

    test('processInput handles machine selection in Hindi', () {
      final engine = AgentDialogueEngine(lang: 'hi');
      engine.startConversation();

      final reply = engine.processInput('ट्रैक्टर');
      expect(reply.isNotEmpty, isTrue);
      expect(engine.state.machineType, equals('tractor'));
      expect(engine.state.currentStep, equals(DialogueStep.askArea));
    });

    test('processInput handles area selection and advances to askDate', () {
      final engine = AgentDialogueEngine(lang: 'ta');
      engine.startConversation();
      engine.processInput('டிராக்டர்');

      final reply = engine.processInput('3 ஏக்கர்');
      expect(reply.isNotEmpty, isTrue);
      expect(engine.state.areaAcres, equals(3.0));
      expect(engine.state.currentStep, equals(DialogueStep.askDate));
    });

    test('processInput handles date selection and advances to search', () {
      final engine = AgentDialogueEngine(lang: 'en');
      engine.startConversation();
      engine.processInput('tractor');
      engine.processInput('2 acres');

      final reply = engine.processInput('tomorrow');
      expect(reply.isNotEmpty, isTrue);
      expect(engine.state.preferredDate, isNotNull);
      expect(engine.state.currentStep, equals(DialogueStep.searchingOwners));
    });

    test('Full multi-turn booking journey with owner selection and confirmation', () {
      final engine = AgentDialogueEngine(lang: 'ta');
      engine.startConversation();

      // Step 1: Machine
      engine.processInput('🚜 டிராக்டர்');
      expect(engine.state.machineType, equals('tractor'));

      // Step 2: Area
      engine.processInput('2 ஏக்கர்');
      expect(engine.state.areaAcres, equals(2.0));

      // Step 3: Date
      engine.processInput('நாளை');
      expect(engine.state.currentStep, equals(DialogueStep.searchingOwners));

      // Simulate search results populated
      final mockMachine = MachineModel(
        id: 'mach_1',
        type: 'tractor',
        model: 'மகேந்திரா 575',
        pricePerHour: 1200,
        operatorIncluded: true,
        status: 'available',
        distanceKm: 3.5,
        owner: UserModel(
          id: 'own_1',
          name: 'செல்வம்',
          phone: '9876543210',
          role: 'owner',
          preferredLanguage: 'ta',
          kycStatus: 'approved',
        ),
      );
      engine.setOwnerResults([mockMachine]);
      expect(engine.state.currentStep, equals(DialogueStep.showOwners));
      expect(engine.state.availableOwners.length, equals(1));

      // Step 4: Select owner by speech "முதல்" (first)
      engine.processInput('முதல்');
      expect(engine.state.selectedOwner, equals(mockMachine));
      expect(engine.state.currentStep, equals(DialogueStep.confirmBooking));

      // Step 5: Confirm booking
      final confirmReply = engine.processInput('சரி');
      expect(confirmReply.isNotEmpty, isTrue);
      expect(engine.state.currentStep, equals(DialogueStep.done));
    });
  });

  group('AgentScript Multi-lingual Prompt Tests', () {
    test('Generates greeting for all 4 languages', () {
      expect(AgentScript.greeting('ta').contains('வணக்கம்'), isTrue);
      expect(AgentScript.greeting('te').contains('నమస్కారం'), isTrue);
      expect(AgentScript.greeting('hi').contains('नमस्ते'), isTrue);
      expect(AgentScript.greeting('en').contains('Hello'), isTrue);
    });

    test('Generates quick-reply machine options for all 4 languages', () {
      expect(AgentScript.machineTypeOptions('ta').length, greaterThanOrEqualTo(4));
      expect(AgentScript.machineTypeOptions('te').length, greaterThanOrEqualTo(4));
      expect(AgentScript.machineTypeOptions('hi').length, greaterThanOrEqualTo(4));
      expect(AgentScript.machineTypeOptions('en').length, greaterThanOrEqualTo(4));
    });

    test('Generates area options for all 4 languages', () {
      expect(AgentScript.areaOptions('ta').first.contains('ஏக்கர்'), isTrue);
      expect(AgentScript.areaOptions('te').first.contains('ఎకరం'), isTrue);
      expect(AgentScript.areaOptions('hi').first.contains('एकड़'), isTrue);
      expect(AgentScript.areaOptions('en').first.contains('acre'), isTrue);
    });
  });
}
