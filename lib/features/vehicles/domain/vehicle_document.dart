enum DocumentType {
  insurance('Insurance'),
  permit('Permit'),
  fitness('Fitness Certificate'),
  puc('PUC (Pollution)');

  final String label;
  const DocumentType(this.label);
}

class VehicleDocument {
  final String id;
  final DocumentType type;
  final String number;
  final DateTime expiryDate;
  final String? fileUrl;

  const VehicleDocument({
    required this.id,
    required this.type,
    required this.number,
    required this.expiryDate,
    this.fileUrl,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  VehicleDocument copyWith({
    String? id,
    DocumentType? type,
    String? number,
    DateTime? expiryDate,
    String? fileUrl,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      number: number ?? this.number,
      expiryDate: expiryDate ?? this.expiryDate,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'number': number,
      'expiryDate': expiryDate.toIso8601String(),
      'fileUrl': fileUrl,
    };
  }

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'] as String,
      type: DocumentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DocumentType.insurance,
      ),
      number: json['number'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      fileUrl: json['fileUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleDocument &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          number == other.number &&
          expiryDate == other.expiryDate &&
          fileUrl == other.fileUrl;

  @override
  int get hashCode => Object.hash(id, type, number, expiryDate, fileUrl);
}
