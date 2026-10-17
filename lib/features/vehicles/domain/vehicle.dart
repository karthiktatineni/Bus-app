import 'vehicle_status.dart';
import 'vehicle_document.dart';

class Vehicle {
  final String id;
  final String registrationNo;
  final String make;
  final String model;
  final int year;
  final String chassisNo;
  final String engineNo;
  final int seats;
  final String fuelType;
  final int odometerKm;
  final String depot;
  final DateTime purchaseDate;
  final VehicleStatus status;
  final List<String> photos;
  final List<VehicleDocument> documents;

  const Vehicle({
    required this.id,
    required this.registrationNo,
    required this.make,
    required this.model,
    required this.year,
    required this.chassisNo,
    required this.engineNo,
    required this.seats,
    required this.fuelType,
    required this.odometerKm,
    required this.depot,
    required this.purchaseDate,
    required this.status,
    this.photos = const [],
    this.documents = const [],
  });

  String get displayName => '$make $model ($registrationNo)';

  Vehicle copyWith({
    String? id,
    String? registrationNo,
    String? make,
    String? model,
    int? year,
    String? chassisNo,
    String? engineNo,
    int? seats,
    String? fuelType,
    int? odometerKm,
    String? depot,
    DateTime? purchaseDate,
    VehicleStatus? status,
    List<String>? photos,
    List<VehicleDocument>? documents,
  }) {
    return Vehicle(
      id: id ?? this.id,
      registrationNo: registrationNo ?? this.registrationNo,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      chassisNo: chassisNo ?? this.chassisNo,
      engineNo: engineNo ?? this.engineNo,
      seats: seats ?? this.seats,
      fuelType: fuelType ?? this.fuelType,
      odometerKm: odometerKm ?? this.odometerKm,
      depot: depot ?? this.depot,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      documents: documents ?? this.documents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrationNo': registrationNo,
      'make': make,
      'model': model,
      'year': year,
      'chassisNo': chassisNo,
      'engineNo': engineNo,
      'seats': seats,
      'fuelType': fuelType,
      'odometerKm': odometerKm,
      'depot': depot,
      'purchaseDate': purchaseDate.toIso8601String(),
      'status': status.name,
      'photos': photos,
      'documents': documents.map((d) => d.toJson()).toList(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      registrationNo: json['registrationNo'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      chassisNo: json['chassisNo'] as String? ?? '',
      engineNo: json['engineNo'] as String? ?? '',
      seats: json['seats'] as int? ?? 40,
      fuelType: json['fuelType'] as String? ?? 'Diesel',
      odometerKm: json['odometerKm'] as int? ?? 0,
      depot: json['depot'] as String? ?? 'Hyderabad Main',
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      status: VehicleStatus.fromStorage(json['status']),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => VehicleDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          registrationNo == other.registrationNo &&
          make == other.make &&
          model == other.model &&
          year == other.year &&
          odometerKm == other.odometerKm &&
          status == other.status;

  @override
  int get hashCode =>
      Object.hash(id, registrationNo, make, model, year, odometerKm, status);
}
