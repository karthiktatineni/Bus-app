import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../mock/mock_data.dart';
import '../../../mock/mock_delay.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final List<AppUser> _users = MockData.generateUsers();
  AppUser? _currentUser;

  MockAuthRepository({AppUser? initialUser}) {
    // Default logged in user is admin Karthik
    _currentUser = initialUser ?? _users.first;
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    // Deliberate simulated failure path
    if (email.contains('fail') || password == 'fail_error') {
      await MockDelay.simulate(shouldFail: true, failureMessage: 'Simulated authentication service outage.');
    }

    await MockDelay.simulate();

    if (password != 'password123' && password != 'admin123') {
      throw const UnauthorizedException('Invalid email or password.');
    }

    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => throw const NotFoundException('No user found with this email.'),
    );

    if (user.status == UserStatus.disabled) {
      throw const UnauthorizedException('This account has been disabled. Contact administrator.');
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
      await MockDelay.simulate(shouldFail: true, failureMessage: 'Unable to send reset email at this time.');
    }
    await MockDelay.simulate();
  }

  @override
  Future<void> changePassword(String current, String next) async {
    if (current == 'fail') {
      await MockDelay.simulate(shouldFail: true, failureMessage: 'Password update service failure.');
    }
    await MockDelay.simulate();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    await MockDelay.simulate(minMs: 100, maxMs: 300);
    return _currentUser;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});
