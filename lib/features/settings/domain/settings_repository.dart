import 'user_settings.dart';
import 'company_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> getUserSettings();
  Future<void> saveUserSettings(UserSettings s);
  Future<CompanySettings> getCompanySettings();
  Future<void> saveCompanySettings(CompanySettings s);
}
