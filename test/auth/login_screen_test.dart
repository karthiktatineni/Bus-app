import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bus_app/core/theme/app_theme.dart';
import 'package:bus_app/features/auth/presentation/login_screen.dart';
import 'package:bus_app/mock/mock_delay.dart';
import 'package:bus_app/features/auth/providers.dart';
import 'package:bus_app/features/auth/data/mock_auth_repository.dart';

void main() {
  setUp(() {
    MockDelay.enableDelays = false;
  });

  tearDown(() {
    MockDelay.enableDelays = true;
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(initiallyAuthenticated: false),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen renders branding, fields, and submit button',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('FleetPulse'), findsOneWidget);
    expect(find.text('ENTERPRISE'), findsOneWidget);
    expect(find.text('Depot Maintenance & Fleet Operations'), findsOneWidget);
    expect(find.text('Depot ID / Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Demo credentials'), findsNothing);
  });

  testWidgets('Login form starts without demo credentials',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final email =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    final password =
        tester.widget<TextFormField>(find.byType(TextFormField).at(1));
    expect(email.controller?.text, isEmpty);
    expect(password.controller?.text, isEmpty);
  });

  testWidgets('Inline validation triggers on invalid email',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Clear email input
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'invalid-email');

    // Tap Sign in
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('Error banner displays on incorrect password submission',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).first, 'driver@example.com');
    // Enter wrong password
    final passwordField = find.byType(TextFormField).at(1);
    await tester.enterText(passwordField, 'wrongpass123');

    // Tap Sign in
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Error banner should be rendered
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });
}
