class CompanySettings {
  final String name;
  final String? logoUrl;
  final List<String> depots;
  final int defaultReminderLeadDays;

  const CompanySettings({
    this.name = 'FleetPulse Bus Operations',
    this.logoUrl,
    this.depots = const [
      'Hyderabad Central',
      'Secunderabad Depot',
      'Warangal Depot'
    ],
    this.defaultReminderLeadDays = 7,
  });

  CompanySettings copyWith({
    String? name,
    String? logoUrl,
    List<String>? depots,
    int? defaultReminderLeadDays,
  }) {
    return CompanySettings(
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      depots: depots ?? this.depots,
      defaultReminderLeadDays:
          defaultReminderLeadDays ?? this.defaultReminderLeadDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'depots': depots,
      'defaultReminderLeadDays': defaultReminderLeadDays,
    };
  }

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    return CompanySettings(
      name: json['name'] as String? ?? 'FleetPulse Bus Operations',
      logoUrl: json['logoUrl'] as String?,
      depots: (json['depots'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['Hyderabad Central', 'Secunderabad Depot', 'Warangal Depot'],
      defaultReminderLeadDays: json['defaultReminderLeadDays'] as int? ?? 7,
    );
  }
}
