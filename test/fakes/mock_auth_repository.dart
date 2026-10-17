import 'package:bus_app/core/errors/app_exception.dart';
import 'package:bus_app/features/auth/domain/app_user.dart';
import 'package:bus_app/features/auth/domain/auth_repository.dart';
import 'mock_data.dart';
import 'mock_delay.dart';

class MockAuthRepository implements AuthRepository {
  final List<AppUser> _users = MockData.generateUsers();
  AppUser? _currentUser;

  MockAuthRepository(
      {AppUser? initialUser, bool initiallyAuthenticated = true}) {
    // Default logged in user is admin Karthik
    _currentUser =
        initiallyAuthenticated ? (initialUser ?? _users.first) : null;
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    // Deliberate simulated failure path
    if (email.contains('fail') || password == 'fail_error') {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated authentication service outage.');
    }

    await MockDelay.simulate();

    if (password != 'password123' && password != 'admin123') {
      throw const UnauthorizedException('Invalid email or password.');
    }

    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () =>
          throw const NotFoundException('No user found with this email.'),
    );

    if (user.status == UserStatus.disabled) {
      throw const UnauthorizedException(
          'This account has been disabled. Contact administrator.');
    }

    _currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    await MockDelay.simulate(minMs: 200, maxMs: 400);
    _currentUser = null;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (email.contains('fail')) {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Unable to send reset email at this time.');
    }
    await MockDelay.simulate();
  }

  @override
  Future<void> changePassword(String current, String next) async {
    if (current == 'fail') {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Password update service failure.');
    }
    await MockDelay.simulate();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    await MockDelay.simulate(minMs: 100, maxMs: 300);
    return _currentUser;
  }
}
