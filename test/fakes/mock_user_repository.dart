import 'package:bus_app/core/errors/app_exception.dart';
import 'package:bus_app/features/auth/domain/app_user.dart';
import 'package:bus_app/features/users/domain/user_repository.dart';
import 'mock_data.dart';
import 'mock_delay.dart';

class MockUserRepository implements UserRepository {
  final List<AppUser> _users = MockData.generateUsers();

  @override
  Future<List<AppUser>> list() async {
    await MockDelay.simulate();
    return List.unmodifiable(_users);
  }

  @override
  Future<AppUser> get(String id) async {
    if (id == 'fail-id' || id == 'usr-error') {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Simulated user fetch failure.');
    }

    await MockDelay.simulate();
    return _users.firstWhere(
      (u) => u.id == id,
      orElse: () => throw NotFoundException('User with ID $id not found.'),
    );
  }

  @override
  Future<AppUser> create({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String phone,
  }) async {
    if (email.contains('fail')) {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated account creation failure.');
    }

    await MockDelay.simulate();
    final newUser = AppUser(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      status: UserStatus.active,
    );
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<AppUser> update(AppUser u, {String? password}) async {
    if (u.id == 'fail-id') {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Simulated user update failure.');
    }

    await MockDelay.simulate();
    final index = _users.indexWhere((user) => user.id == u.id);
    if (index == -1) {
      throw NotFoundException('User with ID ${u.id} not found.');
    }
    _users[index] = u;
    return u;
  }

  @override
  Future<void> remove(String id) async {
    if (id == 'fail-id') {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Simulated user deletion failure.');
    }

    await MockDelay.simulate();
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      throw NotFoundException('User with ID $id not found.');
    }
    _users.removeAt(index);
  }
}
