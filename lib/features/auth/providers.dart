import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/app_user.dart';
import 'domain/auth_repository.dart';
import 'data/supabase_auth_repository.dart';
import '../../core/services/supabase_service.dart';
import 'presentation/auth_controller.dart';

export 'domain/app_user.dart';
export 'domain/auth_repository.dart';
export 'presentation/auth_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});
