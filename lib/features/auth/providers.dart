import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/auth_repository.dart';
import 'data/mock_auth_repository.dart';

export 'domain/app_user.dart';
export 'domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});
