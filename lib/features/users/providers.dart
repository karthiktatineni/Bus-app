import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/user_repository.dart';
import 'data/supabase_user_repository.dart';
import '../../core/services/supabase_service.dart';

export '../auth/domain/app_user.dart';
export 'domain/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return SupabaseUserRepository(ref.watch(supabaseClientProvider));
});
