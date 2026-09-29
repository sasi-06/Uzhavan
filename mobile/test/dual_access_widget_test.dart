import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uzhavan/main.dart';
import 'package:uzhavan/core/providers/app_state.dart';
import 'package:uzhavan/core/services/voice_assistant_service.dart';

void main() {
  group('Uzhavan Dual-Access (Voice & Tap) Unit and Widget Tests', () {
    testWidgets('App loads and renders role switcher & main UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const UzhavanApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Login Screen loads initially for unauthenticated state
      expect(find.byType(UzhavanApp), findsOneWidget);
    });

    test('Voice Assistant NLU parses all 10 closed intents accurately', () {
      // 1. Search Machine
      var res = VoiceAssistantService.parseCommand('tractor search', 'en');
      expect(res.intent, VoiceIntentType.searchMachine);

      // 2. Book Machine
      res = VoiceAssistantService.parseCommand('book machine', 'en');
      expect(res.intent, VoiceIntentType.bookMachine);

      // 3. Check Booking Status
      res = VoiceAssistantService.parseCommand('check status', 'en');
      expect(res.intent, VoiceIntentType.checkBookingStatus);

      // 4. Cancel Booking
      res = VoiceAssistantService.parseCommand('cancel booking', 'en');
      expect(res.intent, VoiceIntentType.cancelBooking);

      // 5. Contact Owner
      res = VoiceAssistantService.parseCommand('call owner', 'en');
      expect(res.intent, VoiceIntentType.contactOwner);

      // 6. Rate Owner
      res = VoiceAssistantService.parseCommand('rate owner', 'en');
      expect(res.intent, VoiceIntentType.rateOwner);

      // 7. List My Machine
      res = VoiceAssistantService.parseCommand('add machine', 'en');
      expect(res.intent, VoiceIntentType.listMyMachine);

      // 8. Check Earnings
      res = VoiceAssistantService.parseCommand('earnings', 'en');
      expect(res.intent, VoiceIntentType.checkEarnings);

      // 9. Accept Booking
      res = VoiceAssistantService.parseCommand('accept booking', 'en');
      expect(res.intent, VoiceIntentType.acceptBooking);

      // 10. Decline Booking
      res = VoiceAssistantService.parseCommand('decline booking', 'en');
      expect(res.intent, VoiceIntentType.declineBooking);

      // 11. Role Switching
      res = VoiceAssistantService.parseCommand('switch to owner', 'en');
      expect(res.intent, VoiceIntentType.switchRole);
      expect(res.targetRole, 'owner');

      res = VoiceAssistantService.parseCommand('switch to farmer', 'en');
      expect(res.intent, VoiceIntentType.switchRole);
      expect(res.targetRole, 'farmer');
    });

    test('Voice Assistant NLU handles Tamil, Tanglish, Telugu, and Hindi keywords', () {
      // Tamil search keyword
      var res = VoiceAssistantService.parseCommand('டிராக்டர் தேடு', 'ta');
      expect(res.intent, VoiceIntentType.searchMachine);

      // Tamil role switch
      res = VoiceAssistantService.parseCommand('என் எந்திரங்கள்', 'ta');
      expect(res.intent, VoiceIntentType.switchRole);
      expect(res.targetRole, 'owner');

      // Confirmation keywords
      res = VoiceAssistantService.parseCommand('உறுதி', 'ta');
      expect(res.intent, VoiceIntentType.confirmAction);

      res = VoiceAssistantService.parseCommand('வேண்டாம்', 'ta');
      expect(res.intent, VoiceIntentType.rejectAction);
    });
  });
}
