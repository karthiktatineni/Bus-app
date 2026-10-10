import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/bill_repository.dart';
import 'domain/ocr_service.dart';
import 'data/mock_bill_repository.dart';
import 'data/mock_ocr_service.dart';

export 'domain/bill.dart';
export 'domain/bill_repository.dart';
export 'domain/ocr_service.dart';

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return MockBillRepository();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  return MockOcrService();
});
