class BillItem {
  final String name;
  final int quantity;
  final double unitCost;
  final double total;

  const BillItem({
    required this.name,
    required this.quantity,
    required this.unitCost,
    required this.total,
  });

  BillItem copyWith({
    String? name,
    int? quantity,
    double? unitCost,
    double? total,
  }) {
    return BillItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unitCost': unitCost,
      'total': total,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unitCost: (json['unitCost'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }
}

class Bill {
  final String id;
  final String vehicleId;
  final String serviceId;
  final String vendor;
  final String billNo;
  final DateTime billDate;
  final List<BillItem> items;
  final double tax;
  final double total;
  final String? imageUrl;
  final double? ocrConfidence;

  const Bill({
    required this.id,
    required this.vehicleId,
    required this.serviceId,
    required this.vendor,
    required this.billNo,
    required this.billDate,
    this.items = const [],
    required this.tax,
    required this.total,
    this.imageUrl,
    this.ocrConfidence,
  });

  Bill copyWith({
    String? id,
    String? vehicleId,
    String? serviceId,
    String? vendor,
    String? billNo,
    DateTime? billDate,
    List<BillItem>? items,
    double? tax,
    double? total,
    String? imageUrl,
    double? ocrConfidence,
  }) {
    return Bill(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceId: serviceId ?? this.serviceId,
      vendor: vendor ?? this.vendor,
      billNo: billNo ?? this.billNo,
      billDate: billDate ?? this.billDate,
      items: items ?? this.items,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      imageUrl: imageUrl ?? this.imageUrl,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'serviceId': serviceId,
      'vendor': vendor,
      'billNo': billNo,
      'billDate': billDate.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'tax': tax,
      'total': total,
      'imageUrl': imageUrl,
      'ocrConfidence': ocrConfidence,
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      serviceId: json['serviceId'] as String,
      vendor: json['vendor'] as String,
      billNo: json['billNo'] as String,
      billDate: DateTime.parse(json['billDate'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BillItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bill &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          billNo == other.billNo &&
          total == other.total;

  @override
  int get hashCode => Object.hash(id, billNo, total);
}
