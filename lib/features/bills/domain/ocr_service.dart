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

  const OcrResult({
    this.vendor,
    this.billNo,
    this.billDate,
    this.total,
    this.confidence = 0.95,
    this.rawLines = const [],
    this.items = const [],
  });
}

abstract class OcrService {
  Future<OcrResult> scanBill(String imagePath);
}
