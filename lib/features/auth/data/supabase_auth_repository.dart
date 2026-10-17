import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';
import '../domain/app_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<AppUser> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Login failed: no user returned');
    }
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();
    final appUser = _profileToAppUser(profile);
    if (appUser.status != UserStatus.active) {
      await _client.auth.signOut();
      throw StateError(
          'This account is disabled. Contact your company administrator.');
    }
    return appUser;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> changePassword(String current, String next) async {
    await _client.auth.updateUser(UserAttributes(password: next));
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .single();
      final appUser = _profileToAppUser(profile);
      if (appUser.status != UserStatus.active) {
        await _client.auth.signOut();
        return null;
      }
      return appUser;
    } catch (_) {
      return null;
    }
  }

  AppUser _profileToAppUser(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      name: row['name'] as String,
      email: row['email'] as String,
      phone: row['phone'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == row['role'],
        orElse: () => UserRole.staff,
      ),
      status: UserStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => UserStatus.active,
      ),
      avatarUrl: row['avatar_url'] as String?,
    );
  }
}
