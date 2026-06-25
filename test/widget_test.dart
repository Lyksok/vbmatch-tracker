import 'package:flutter_test/flutter_test.dart';
import 'package:volley_score/main.dart';

void main() {
  testWidgets('App smoke test - starts on home screen with title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VolleyScoreApp());

    // Verify that our app starts on the home screen with the title Volley Score 🏐
    expect(find.text('Volley Score 🏐'), findsOneWidget);
    
    // Verify that the new match button is visible
    expect(find.text('NOUVEAU MATCH'), findsOneWidget);
  });
}
