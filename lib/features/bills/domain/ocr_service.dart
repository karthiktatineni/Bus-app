class OcrResult {
  final String? vendor;
  final String? billNo;
  final DateTime? billDate;
  final double? total;
  final double confidence;
  final List<String> rawLines;

  const OcrResult({
    this.vendor,
    this.billNo,
    this.billDate,
    this.total,
    this.confidence = 0.95,
    this.rawLines = const [],
  });
}

abstract class OcrService {
  Future<OcrResult> scanBill(String imagePath);
}
