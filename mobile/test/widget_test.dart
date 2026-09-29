import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uzhavan/main.dart';
import 'package:uzhavan/core/providers/app_state.dart';

void main() {
  testWidgets('App loads initial UI successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const UzhavanApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(UzhavanApp), findsOneWidget);
  });
}
