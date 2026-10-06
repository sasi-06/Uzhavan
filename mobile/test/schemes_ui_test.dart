import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uzhavan/core/providers/app_state.dart';
import 'package:uzhavan/core/models/scheme_model.dart';
import 'package:uzhavan/features/schemes/schemes_screen.dart';
import 'package:uzhavan/features/schemes/scheme_detail_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Government Schemes UI Verification Tests', () {
    testWidgets('SchemesScreen renders properly with role toggles and categories', (tester) async {
      await tester.pumpWidget(createTestWidget(const SchemesScreen()));
      await tester.pumpAndSettle();

      // Verify title is rendered
      expect(find.textContaining('திட்டங்கள்'), findsOneWidget);

      // Verify role buttons exist
      expect(find.text('விவசாயி'), findsOneWidget);
      expect(find.text('இயந்திர உரிமையாளர்'), findsOneWidget);

      // Verify category filter chips
      expect(find.text('அனைத்தும்'), findsOneWidget);
      expect(find.text('மானியம்'), findsOneWidget);

      // Verify at least one scheme card renders
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Role toggle switches between Farmer and Machine Owner', (tester) async {
      await tester.pumpWidget(createTestWidget(const SchemesScreen(initialRole: 'FARMER')));
      await tester.pumpAndSettle();

      // Tap on Machine Owner tab
      final ownerTab = find.text('இயந்திர உரிமையாளர்');
      expect(ownerTab, findsOneWidget);
      await tester.tap(ownerTab);
      await tester.pumpAndSettle();

      // Verify interaction succeeded without layout errors or exceptions
      expect(find.byType(SchemesScreen), findsOneWidget);
    });

    testWidgets('SchemeDetailSheet displays complete scheme breakdown and actions', (tester) async {
      final sampleScheme = SchemeModel(
        id: 'test-smam',
        targetRole: 'MACHINE_OWNER',
        category: 'MACHINERY_SUBSIDY',
        subsidyBadge: '50% மானியம்',
        title: 'வேளாண் இயந்திரமயமாக்கல் திட்டம் (SMAM)',
        shortDesc: 'புதிய டிராக்டர் வாங்க 50% அரசு மானியம்.',
        overview: 'மத்திய மற்றும் தமிழக அரசு வழங்கும் திட்டம்.',
        benefits: ['ரூ. 5 லட்சம் வரை மானியம்', 'நேரடி வங்கி பரிமாற்றம்'],
        eligibility: ['விவசாயிகள் மற்றும் இயந்திர வாடகை தொழில் செய்வோர்'],
        documentsRequired: ['ஆதார் அட்டை', 'பட்டா/சிட்டா நகல்'],
        howToApply: 'agrimachinery.nic.in இணையதளத்தில் பதிவு செய்யவும்.',
        applyUrl: 'https://agrimachinery.nic.in',
        helpline: '1800-180-1551',
        state: 'All India',
        currentLang: 'ta',
      );

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SchemeDetailSheet.show(ctx, sampleScheme),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open detail bottom sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet title and badge
      expect(find.text('50% மானியம்'), findsOneWidget);
      expect(find.text('வேளாண் இயந்திரமயமாக்கல் திட்டம் (SMAM)'), findsOneWidget);

      // Verify breakdown sections
      expect(find.text('திட்ட விளக்கம்'), findsOneWidget);
      expect(find.text('முக்கிய பலன்கள்'), findsOneWidget);
      expect(find.text('தகுதிகள் (யாரெல்லாம் பெறலாம்)'), findsOneWidget);
      expect(find.text('தேவையான ஆவணங்கள்'), findsOneWidget);
      expect(find.text('விண்ணப்பிக்கும் முறை'), findsOneWidget);

      // Verify action buttons
      expect(find.text('அதிகாரப்பூர்வ தளம்'), findsOneWidget);
      expect(find.text('1800-180-1551'), findsOneWidget);
    });
  });
}
