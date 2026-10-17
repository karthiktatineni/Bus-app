import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/settings_repository.dart';
import 'data/supabase_settings_repository.dart';
import '../../core/services/supabase_service.dart';

export 'domain/user_settings.dart';
export 'domain/company_settings.dart';
export 'domain/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SupabaseSettingsRepository(ref.watch(supabaseClientProvider));
});
