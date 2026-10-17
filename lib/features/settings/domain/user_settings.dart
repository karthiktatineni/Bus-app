class UserSettings {
  final String themeMode; // 'system', 'light', 'dark'
  final String language;
  final String distanceUnit;
  final String currency;
  final String dateFormat;
  final bool notificationsEnabled;
  final bool serviceRemindersEnabled;
  final int serviceReminderLeadDays;
  final bool docExpiryRemindersEnabled;
  final int docExpiryLeadDays;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool biometricLock;

  const UserSettings({
    this.themeMode = 'system',
    this.language = 'en',
    this.distanceUnit = 'km',
    this.currency = 'INR',
    this.dateFormat = 'dd/MM/yyyy',
    this.notificationsEnabled = true,
    this.serviceRemindersEnabled = true,
    this.serviceReminderLeadDays = 7,
    this.docExpiryRemindersEnabled = true,
    this.docExpiryLeadDays = 15,
    this.pushEnabled = true,
    this.emailEnabled = false,
    this.biometricLock = false,
  });

  UserSettings copyWith({
    String? themeMode,
    String? language,
    String? distanceUnit,
    String? currency,
    String? dateFormat,
    bool? notificationsEnabled,
    bool? serviceRemindersEnabled,
    int? serviceReminderLeadDays,
    bool? docExpiryRemindersEnabled,
    int? docExpiryLeadDays,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? biometricLock,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      serviceRemindersEnabled:
          serviceRemindersEnabled ?? this.serviceRemindersEnabled,
      serviceReminderLeadDays:
          serviceReminderLeadDays ?? this.serviceReminderLeadDays,
      docExpiryRemindersEnabled:
          docExpiryRemindersEnabled ?? this.docExpiryRemindersEnabled,
      docExpiryLeadDays: docExpiryLeadDays ?? this.docExpiryLeadDays,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      biometricLock: biometricLock ?? this.biometricLock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'language': language,
      'distanceUnit': distanceUnit,
      'currency': currency,
      'dateFormat': dateFormat,
      'notificationsEnabled': notificationsEnabled,
      'serviceRemindersEnabled': serviceRemindersEnabled,
      'serviceReminderLeadDays': serviceReminderLeadDays,
      'docExpiryRemindersEnabled': docExpiryRemindersEnabled,
      'docExpiryLeadDays': docExpiryLeadDays,
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'biometricLock': biometricLock,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      distanceUnit: json['distanceUnit'] as String? ?? 'km',
      currency: json['currency'] as String? ?? 'INR',
      dateFormat: json['dateFormat'] as String? ?? 'dd/MM/yyyy',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      serviceRemindersEnabled: json['serviceRemindersEnabled'] as bool? ?? true,
      serviceReminderLeadDays: json['serviceReminderLeadDays'] as int? ?? 7,
      docExpiryRemindersEnabled:
          json['docExpiryRemindersEnabled'] as bool? ?? true,
      docExpiryLeadDays: json['docExpiryLeadDays'] as int? ?? 15,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? false,
      biometricLock: json['biometricLock'] as bool? ?? false,
    );
  }
}
