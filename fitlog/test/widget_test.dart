import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitlog/main.dart';

void main() {
  testWidgets('FitLog navigation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Cannot connect to the backend.'), findsNothing);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Workout'));
    await tester.pump();
    expect(find.text('Select Category'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pump();
    expect(find.text('No workout history.'), findsOneWidget);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    final BottomNavigationBar navigationBar = tester.widget(
      find.byType(BottomNavigationBar),
    );
    expect(navigationBar.items.length, 3);
    expect(navigationBar.items[0].label, 'Home');
    expect(navigationBar.items[1].label, 'Workout');
    expect(navigationBar.items[2].label, 'History');
  });
}
