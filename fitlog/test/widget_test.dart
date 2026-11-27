import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitlog/main.dart';
import 'package:fitlog/screens/login_screen.dart';
import 'package:fitlog/screens/splash_screen.dart';
import 'package:fitlog/widgets/fitlog_logo.dart';

void main() {
  testWidgets('splash displays the logo for five seconds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(FitLogLogo), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(seconds: 4, milliseconds: 999));
    expect(find.byType(LoginScreen), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('valid demo login opens the workout app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login-username')), 'Fitlog');
    await tester.enterText(find.byKey(const Key('login-password')), '123');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BottomNavigationBar), findsOneWidget);
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

  testWidgets('invalid credentials stay on the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login-username')), 'Fitlog');
    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Invalid username or password.'), findsOneWidget);
  });
}
