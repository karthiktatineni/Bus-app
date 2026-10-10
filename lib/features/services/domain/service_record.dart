enum ServiceType {
  regular('Regular Maintenance'),
  oilChange('Oil & Filter Change'),
  brakeService('Brake Overhaul'),
  clutchReplacement('Clutch & Transmission'),
  electrical('Electrical & Battery'),
  tyreReplacement('Tyre Rotation / Replacement'),
  majorRepair('Major Overhaul');

  final String label;
  const ServiceType(this.label);
}

enum PhotoType { before, after, part, bill }

class ServicePart {
  final String id;
  final String name;
  final int quantity;
  final double costPerUnit;
  final double totalCost;
  final String? partNumber;

  const ServicePart({
    required this.id,
    required this.name,
    required this.quantity,
    required this.costPerUnit,
    required this.totalCost,
    this.partNumber,
  });

  ServicePart copyWith({
    String? id,
    String? name,
    int? quantity,
    double? costPerUnit,
    double? totalCost,
    String? partNumber,
  }) {
    return ServicePart(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      totalCost: totalCost ?? this.totalCost,
      partNumber: partNumber ?? this.partNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'costPerUnit': costPerUnit,
      'totalCost': totalCost,
      'partNumber': partNumber,
    };
  }

  factory ServicePart.fromJson(Map<String, dynamic> json) {
    return ServicePart(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      costPerUnit: (json['costPerUnit'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      partNumber: json['partNumber'] as String?,
    );
  }
}

class ServicePhoto {
  final String id;
  final String url;
  final PhotoType type;
  final String? caption;
  final String? partId;

  const ServicePhoto({
    required this.id,
    required this.url,
    required this.type,
    this.caption,
    this.partId,
  });

  ServicePhoto copyWith({
    String? id,
    String? url,
    PhotoType? type,
    String? caption,
    String? partId,
  }) {
    return ServicePhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      partId: partId ?? this.partId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type.name,
      'caption': caption,
      'partId': partId,
    };
  }

  factory ServicePhoto.fromJson(Map<String, dynamic> json) {
    return ServicePhoto(
      id: json['id'] as String,
      url: json['url'] as String,
      type: PhotoType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PhotoType.part,
      ),
      caption: json['caption'] as String?,
      partId: json['partId'] as String?,
    );
  }
}

class ServiceRecord {
  final String id;
  final String vehicleId;
  final ServiceType type;
  final DateTime date;
  final int odometerKm;
  final String workshop;
  final String mechanic;
  final String notes;
  final List<ServicePart> parts;
  final double labourCost;
  final double tax;
  final double total;
  final List<ServicePhoto> photos;
  final String? billId;

  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.date,
    required this.odometerKm,
    required this.workshop,
    required this.mechanic,
    required this.notes,
    this.parts = const [],
    required this.labourCost,
    required this.tax,
    required this.total,
    this.photos = const [],
    this.billId,
  });

  ServiceRecord copyWith({
    String? id,
    String? vehicleId,
    ServiceType? type,
    DateTime? date,
    int? odometerKm,
    String? workshop,
    String? mechanic,
    String? notes,
    List<ServicePart>? parts,
    double? labourCost,
    double? tax,
    double? total,
    List<ServicePhoto>? photos,
    String? billId,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      date: date ?? this.date,
      odometerKm: odometerKm ?? this.odometerKm,
      workshop: workshop ?? this.workshop,
      mechanic: mechanic ?? this.mechanic,
      notes: notes ?? this.notes,
      parts: parts ?? this.parts,
      labourCost: labourCost ?? this.labourCost,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      photos: photos ?? this.photos,
      billId: billId ?? this.billId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type.name,
      'date': date.toIso8601String(),
      'odometerKm': odometerKm,
      'workshop': workshop,
      'mechanic': mechanic,
      'notes': notes,
      'parts': parts.map((p) => p.toJson()).toList(),
      'labourCost': labourCost,
      'tax': tax,
      'total': total,
      'photos': photos.map((p) => p.toJson()).toList(),
      'billId': billId,
    };
  }

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      type: ServiceType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ServiceType.regular,
      ),
      date: DateTime.parse(json['date'] as String),
      odometerKm: json['odometerKm'] as int,
      workshop: json['workshop'] as String,
      mechanic: json['mechanic'] as String,
      notes: json['notes'] as String? ?? '',
      parts: (json['parts'] as List<dynamic>?)
              ?.map((e) => ServicePart.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      labourCost: (json['labourCost'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => ServicePhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      billId: json['billId'] as String?,
    );
  }
}
