import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/domain/app_user.dart';
import '../domain/user_repository.dart';

class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<AppUser>> list() async {
    final rows = await _client.from('profiles').select().order('name');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<AppUser> get(String id) async =>
      _fromRow(await _client.from('profiles').select().eq('id', id).single());

  @override
  Future<AppUser> invite(
      {required String name,
      required String email,
      required String password,
      required UserRole role,
      required String phone}) async {
    final result = await _client.functions.invoke('manage-user', body: {
      'action': 'create',
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role.name,
    });
    if (result.status < 200 || result.status >= 300) {
      throw StateError('User invitation failed.');
    }
    final id = (result.data as Map<String, dynamic>)['id'] as String;
    return get(id);
  }

  @override
  Future<AppUser> update(AppUser user, {String? password}) async {
    final result = await _client.functions.invoke('manage-user', body: {
      'action': 'update',
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'role': user.role.name,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    if (result.status < 200 || result.status >= 300) {
      throw StateError('User update failed.');
    }
    final id = (result.data as Map<String, dynamic>)['id'] as String;
    return get(id);
  }

  @override
  Future<void> remove(String id) async {
    final result = await _client.functions.invoke('manage-user', body: {
      'action': 'remove',
      'id': id,
    });
    if (result.status < 200 || result.status >= 300) {
      throw StateError('User removal failed.');
    }
  }

  AppUser _fromRow(Map<String, dynamic> row) => AppUser(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String,
        phone: row['phone'] as String? ?? '',
        role: UserRole.values.firstWhere((v) => v.name == row['role'],
            orElse: () => UserRole.staff),
        status: UserStatus.values.firstWhere((v) => v.name == row['status'],
            orElse: () => UserStatus.disabled),
        avatarUrl: row['avatar_url'] as String?,
      );
}
