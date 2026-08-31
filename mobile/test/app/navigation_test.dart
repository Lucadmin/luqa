import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_luqa.dart';

void main() {
  testWidgets('uses bottom navigation on a compact Android-sized window', (
    tester,
  ) async {
    await pumpLuqa(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Continue workout'), findsOneWidget);
  });

  testWidgets('uses a navigation rail on expanded windows', (tester) async {
    await pumpLuqa(tester, size: const Size(900, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
