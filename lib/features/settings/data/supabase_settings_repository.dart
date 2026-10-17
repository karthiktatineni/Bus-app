import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/company_settings.dart';
import '../domain/settings_repository.dart';
import '../domain/user_settings.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this._client);
  final SupabaseClient _client;

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw StateError('Sign in before accessing settings.'));

  Future<String> get _companyId async {
    final row = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', _userId)
        .single();
    return row['company_id'] as String;
  }

  @override
  Future<UserSettings> getUserSettings() async {
    final row = await _client
        .from('user_settings')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    if (row == null) return const UserSettings();
    return UserSettings(
      themeMode: row['theme_mode'] as String? ?? 'system',
      distanceUnit: row['distance_unit'] as String? ?? 'km',
      currency: row['currency'] as String? ?? 'INR',
      dateFormat: row['date_format'] as String? ?? 'dd MMM yyyy',
      serviceRemindersEnabled:
          row['service_reminders_enabled'] as bool? ?? true,
      serviceReminderLeadDays: row['service_reminders_lead_days'] as int? ?? 14,
      docExpiryRemindersEnabled:
          row['doc_expiry_reminders_enabled'] as bool? ?? true,
      docExpiryLeadDays: row['doc_expiry_reminders_lead_days'] as int? ?? 15,
    );
  }

  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    await _client.from('user_settings').upsert({
      'user_id': _userId,
      'theme_mode': settings.themeMode,
      'distance_unit': settings.distanceUnit,
      'currency': settings.currency,
      'date_format': settings.dateFormat,
      'service_reminders_enabled': settings.serviceRemindersEnabled,
      'service_reminders_lead_days': settings.serviceReminderLeadDays,
      'doc_expiry_reminders_enabled': settings.docExpiryRemindersEnabled,
      'doc_expiry_reminders_lead_days': settings.docExpiryLeadDays,
    });
  }

  @override
  Future<CompanySettings> getCompanySettings() async {
    final companyId = await _companyId;
    final row = await _client
        .from('companies')
        .select('name,logo_url,default_reminder_lead_days')
        .eq('id', companyId)
        .single();
    return CompanySettings(
        name: row['name'] as String,
        logoUrl: row['logo_url'] as String?,
        defaultReminderLeadDays:
            row['default_reminder_lead_days'] as int? ?? 14);
  }

  @override
  Future<void> saveCompanySettings(CompanySettings settings) async {
    final companyId = await _companyId;
    await _client.from('companies').update({
      'name': settings.name,
      'logo_url': settings.logoUrl,
      'default_reminder_lead_days': settings.defaultReminderLeadDays,
    }).eq('id', companyId);
  }
}
