class OcrLineItem {
  final String name;
  final int quantity;
  final double total;

  const OcrLineItem({
    required this.name,
    required this.quantity,
    required this.total,
  });
}

class OcrResult {
  final String? vendor;
  final String? billNo;
  final DateTime? billDate;
  final double? total;
  final double confidence;
  final List<String> rawLines;
  final List<OcrLineItem> items;
  final String? mechanic;
  final int? odometerKm;
  final String? vehicleRegistration;
  final String? serviceDescription;
  final double? laborTotal;

  const OcrResult({
    this.vendor,
    this.billNo,
    this.billDate,
    this.total,
    this.confidence = 0.95,
    this.rawLines = const [],
    this.items = const [],
    this.mechanic,
    this.odometerKm,
    this.vehicleRegistration,
    this.serviceDescription,
    this.laborTotal,
  });
}

abstract class OcrService {
  Future<OcrResult> scanBill(String imagePath);
}
