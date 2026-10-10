import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/settings_repository.dart';
import 'data/mock_settings_repository.dart';

export 'domain/user_settings.dart';
export 'domain/company_settings.dart';
export 'domain/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MockSettingsRepository();
});
