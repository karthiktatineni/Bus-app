import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseMediaStorage {
  SupabaseMediaStorage(this._client);
  final SupabaseClient _client;

  Future<String> upload(
      {required String bucket,
      required String companyId,
      required String parentId,
      required String filePath}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in before uploading files.');
    final ext = p.extension(filePath).toLowerCase();
    final objectPath =
        '$companyId/$parentId/${const Uuid().v4()}${ext.isEmpty ? '.jpg' : ext}';
    await _client.storage.from(bucket).upload(objectPath, File(filePath),
        fileOptions: const FileOptions(upsert: false));
    return objectPath;
  }

  Future<String> signedUrl(String bucket, String objectPath) {
    if (objectPath.startsWith('https://') || objectPath.startsWith('http://')) {
      return Future.value(objectPath);
    }
    return _client.storage.from(bucket).createSignedUrl(objectPath, 3600);
  }
}
