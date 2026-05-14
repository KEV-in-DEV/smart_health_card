import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_card/main.dart';

void main() {
  testWidgets('Smart Health Card affiche l’accès public', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('Smart Health Card'), findsOneWidget);
    expect(find.text('Accès public'), findsOneWidget);
    expect(find.text('Scanner un QR code sans connexion'), findsOneWidget);
    expect(find.text('Connexion agent'), findsOneWidget);
  });
}
