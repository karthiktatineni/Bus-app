import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bus_app/features/auth/presentation/auth_controller.dart';
import 'package:bus_app/features/auth/providers.dart';
import 'package:bus_app/mock/mock_delay.dart';

void main() {
  setUp(() {
    MockDelay.enableDelays = false;
  });

  tearDown(() {
    MockDelay.enableDelays = true;
  });

  test('initial auth state is unauthenticated', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(authControllerProvider);
    expect(state.isAuthenticated, isFalse);
    expect(state.user, isNull);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('signIn succeeds with valid credentials', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final success = await container
        .read(authControllerProvider.notifier)
        .signIn('karthik@fleetpulse.com', 'password123');

    expect(success, isTrue);
    final state = container.read(authControllerProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.user?.name, 'Karthik Tatineni');
    expect(state.user?.role, UserRole.admin);
    expect(state.errorMessage, isNull);
  });

  test('signIn fails with incorrect password and sets error message', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final success = await container
        .read(authControllerProvider.notifier)
        .signIn('karthik@fleetpulse.com', 'wrongpassword');

    expect(success, isFalse);
    final state = container.read(authControllerProvider);
    expect(state.isAuthenticated, isFalse);
    expect(state.errorMessage, isNotNull);
  });

  test('signOut clears user session', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .signIn('karthik@fleetpulse.com', 'password123');
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);

    await container.read(authControllerProvider.notifier).signOut();
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(container.read(authControllerProvider).user, isNull);
  });

  test('sendPasswordReset completes successfully', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final success = await container
        .read(authControllerProvider.notifier)
        .sendPasswordReset('karthik@fleetpulse.com');

    expect(success, isTrue);
  });
}
