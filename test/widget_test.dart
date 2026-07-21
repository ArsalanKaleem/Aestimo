import 'package:careergpt/core/gemini/gemini_providers.dart';
import 'package:careergpt/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Aestimo app smoke test', (WidgetTester tester) async {
    // 1. Build the container with overrides as done in main()
    final container = ProviderContainer(
      overrides: buildGeminiOverrides(),
    );

    // 2. Build our app within UncontrolledProviderScope
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AestimoApp(),
      ),
    );

    // 3. Trigger a frame
    await tester.pumpAndSettle();

    // 4. Update your expectations based on your actual UI content
    // Since 'Counter' was a default example, you should replace these
    // with expects that verify your actual home screen content.
    // Example: expect(find.text('Welcome to Aestimo'), findsOneWidget);
  });
}
