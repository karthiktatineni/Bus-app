class VehiclePhoto {
  final String id;
  final String vehicleId;
  final String url;
  final String? caption;
  final DateTime uploadedAt;

  const VehiclePhoto({
    required this.id,
    required this.vehicleId,
    required this.url,
    this.caption,
    required this.uploadedAt,
  });

  VehiclePhoto copyWith({
    String? id,
    String? vehicleId,
    String? url,
    String? caption,
    DateTime? uploadedAt,
  }) {
    return VehiclePhoto(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      url: url ?? this.url,
      caption: caption ?? this.caption,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'url': url,
      'caption': caption,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory VehiclePhoto.fromJson(Map<String, dynamic> json) {
    return VehiclePhoto(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      url: json['url'] as String,
      caption: json['caption'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehiclePhoto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          vehicleId == other.vehicleId &&
          url == other.url &&
          caption == other.caption &&
          uploadedAt == other.uploadedAt;

  @override
  int get hashCode => Object.hash(id, vehicleId, url, caption, uploadedAt);
}
