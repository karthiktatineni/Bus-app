import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mock/mock_delay.dart';
import '../domain/user_settings.dart';
import '../domain/company_settings.dart';
import '../domain/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  UserSettings _userSettings = const UserSettings();
  CompanySettings _companySettings = const CompanySettings();

  @override
  Future<UserSettings> getUserSettings() async {
    await MockDelay.simulate(minMs: 200, maxMs: 400);
    return _userSettings;
  }

  @override
  Future<void> saveUserSettings(UserSettings s) async {
    if (s.language == 'fail') {
      await MockDelay.simulate(shouldFail: true, failureMessage: 'Simulated user settings save error.');
    }
    await MockDelay.simulate();
    _userSettings = s;
  }

  @override
  Future<CompanySettings> getCompanySettings() async {
    await MockDelay.simulate(minMs: 200, maxMs: 400);
    return _companySettings;
  }

  @override
  Future<void> saveCompanySettings(CompanySettings s) async {
    if (s.name.contains('FAIL')) {
      await MockDelay.simulate(shouldFail: true, failureMessage: 'Simulated company settings save error.');
    }
    await MockDelay.simulate();
    _companySettings = s;
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MockSettingsRepository();
});
