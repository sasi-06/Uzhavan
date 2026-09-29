import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uzhavan/core/providers/accessibility_provider.dart';
import 'package:uzhavan/core/theme/accessibility_theme.dart';
import 'package:uzhavan/core/services/haptic_feedback_service.dart';
import 'package:uzhavan/core/services/spotlight_screen_reader.dart';
import 'package:uzhavan/core/widgets/machine_type_tile.dart';
import 'package:uzhavan/core/widgets/dirty_hands_gesture_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. AccessibilityProvider Tests', () {
    test('Initial default values', () {
      final provider = AccessibilityProvider();
      expect(provider.isHighContrast, false);
      expect(provider.isPictogramMode, false);
      expect(provider.dirtyHandsMode, false);
      expect(provider.fontSizeScale, 1.0);
      expect(provider.hapticFeedbackEnabled, true);
      expect(provider.spotlightActive, false);
    });

    test('State mutation and toggles', () async {
      final provider = AccessibilityProvider();

      await provider.setHighContrast(true);
      expect(provider.isHighContrast, true);

      await provider.setPictogramMode(true);
      expect(provider.isPictogramMode, true);

      await provider.setDirtyHandsMode(true);
      expect(provider.dirtyHandsMode, true);

      await provider.setFontSizeScale(1.4);
      expect(provider.fontSizeScale, 1.4);

      await provider.setHapticFeedback(false);
      expect(provider.hapticFeedbackEnabled, false);
    });

    test('Spotlight state controls', () {
      final provider = AccessibilityProvider();
      expect(provider.spotlightActive, false);

      provider.startSpotlight();
      expect(provider.spotlightActive, true);
      expect(provider.activeSpotlightIndex, 0);

      provider.updateSpotlight(2, 'Test section text');
      expect(provider.activeSpotlightIndex, 2);
      expect(provider.spotlightText, 'Test section text');

      provider.stopSpotlight();
      expect(provider.spotlightActive, false);
      expect(provider.activeSpotlightIndex, -1);
    });
  });

  group('2. AccessibilityTheme Resolver Tests', () {
    testWidgets('Standard Mode Color & Touch Target Resolution', (tester) async {
      late BuildContext testContext;
      final provider = AccessibilityProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(AccessibilityTheme.getMinTouchTarget(testContext), 48.0);
      expect(AccessibilityTheme.getBackgroundColor(testContext), isNot(AccessibilityTheme.sunlightBlack));
    });

    testWidgets('High Contrast Mode Resolution', (tester) async {
      late BuildContext testContext;
      final provider = AccessibilityProvider();
      await provider.setHighContrast(true);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                testContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(AccessibilityTheme.getMinTouchTarget(testContext), 64.0);
      expect(AccessibilityTheme.getBackgroundColor(testContext), AccessibilityTheme.sunlightBlack);
      expect(AccessibilityTheme.getPrimaryColor(testContext), AccessibilityTheme.sunlightYellow);
    });
  });

  group('3. Haptic & Spotlight Service Unit Tests', () {
    test('HapticFeedbackService executes cleanly without throwing', () async {
      await HapticFeedbackService.selectionClick();
      await HapticFeedbackService.micPulse();
      await HapticFeedbackService.successBuzz();
      await HapticFeedbackService.alertPulse();
    });

    test('SpotlightItem creation', () {
      final item = SpotlightItem(index: 0, label: 'Tractor', textToSpeak: 'Tractor ₹800 per hour');
      expect(item.index, 0);
      expect(item.label, 'Tractor');
      expect(item.textToSpeak, 'Tractor ₹800 per hour');
    });
  });

  group('4. Widget Tests', () {
    testWidgets('MachineTypeTile renders correctly', (tester) async {
      final provider = AccessibilityProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: MachineTypeTile(
                type: 'tractor',
                lang: 'ta',
                selected: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('டிராக்டர்'), findsOneWidget);
    });

    testWidgets('DirtyHandsGestureWrapper renders badge when active', (tester) async {
      final provider = AccessibilityProvider();
      await provider.setDirtyHandsMode(true);

      bool triggered = false;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: DirtyHandsGestureWrapper(
                onGestureTriggered: () => triggered = true,
                child: const Text('Child Screen'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child Screen'), findsOneWidget);
      expect(find.text('இருமுறை தொடவும் (Voice)'), findsOneWidget);
    });
  });
}
