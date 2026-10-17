import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/domain/app_user.dart';
import '../domain/user_repository.dart';

class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository(this._client, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _backendUrl = const String.fromEnvironment(
          'FLEET_BACKEND_URL',
          defaultValue: 'https://fleetpulse-ocr.onrender.com',
        ).replaceFirst(RegExp(r'/+$'), '');

  final SupabaseClient _client;
  final http.Client _httpClient;
  final String _backendUrl;

  @override
  Future<List<AppUser>> list() async {
    final rows = await _client.from('profiles').select().order('name');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<AppUser> get(String id) async =>
      _fromRow(await _client.from('profiles').select().eq('id', id).single());

  @override
  Future<AppUser> create(
      {required String name,
      required String email,
      required String password,
      required UserRole role,
      required String phone}) async {
    final result = await _adminRequest({
      'action': 'create',
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role.name,
    });
    final id = result['id'] as String;
    return get(id);
  }

  @override
  Future<AppUser> update(AppUser user, {String? password}) async {
    final result = await _adminRequest({
      'action': 'update',
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'role': user.role.name,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    final id = result['id'] as String;
    return get(id);
  }

  @override
  Future<void> remove(String id) async {
    await _adminRequest({
      'action': 'remove',
      'id': id,
    });
  }

  Future<Map<String, dynamic>> _adminRequest(Map<String, dynamic> body) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw StateError('Sign in as a company administrator to manage users.');
    }
    final response = await _httpClient
        .post(
          Uri.parse('$_backendUrl/admin/users'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // Use the HTTP status if the service returned a non-JSON response.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload['detail'];
      throw StateError(detail is String && detail.isNotEmpty
          ? detail
          : 'User management request failed (HTTP ${response.statusCode}).');
    }
    return payload;
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
