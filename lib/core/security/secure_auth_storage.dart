import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores Supabase sessions in the platform secure store and migrates an
/// existing SharedPreferences session the first time this adapter is used.
class SecureAuthStorage extends LocalStorage {
  SecureAuthStorage({required String persistSessionKey})
      : _persistSessionKey = persistSessionKey,
        _legacyStorage = SharedPreferencesLocalStorage(
          persistSessionKey: persistSessionKey,
        );

  final String _persistSessionKey;
  final SharedPreferencesLocalStorage _legacyStorage;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    try {
      final securedSession = await _secureStorage.read(key: _persistSessionKey);
      if (securedSession != null) return;

      await _legacyStorage.initialize();
      final legacySession = await _legacyStorage.accessToken();
      if (legacySession == null || legacySession.isEmpty) return;

      await _secureStorage.write(
        key: _persistSessionKey,
        value: legacySession,
      );
      await _legacyStorage.removePersistedSession();
    } catch (_) {
      // Legacy SharedPreferences migration failed or unavailable; continue securely
    }
  }

  @override
  Future<bool> hasAccessToken() async =>
      (await _secureStorage.read(key: _persistSessionKey)) != null;

  @override
  Future<String?> accessToken() => _secureStorage.read(key: _persistSessionKey);

  @override
  Future<void> removePersistedSession() async {
    await _secureStorage.delete(key: _persistSessionKey);
    try {
      await _legacyStorage.removePersistedSession();
    } catch (_) {}
  }

  @override
  Future<void> persistSession(String persistSessionString) =>
      _secureStorage.write(
        key: _persistSessionKey,
        value: persistSessionString,
      );
}
