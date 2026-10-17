import 'package:bus_app/features/bills/domain/ocr_service.dart';
import 'mock_delay.dart';

class MockOcrService implements OcrService {
  @override
  Future<OcrResult> scanBill(String imagePath) async {
    // Deliberate failure if imagePath indicates failure
    if (imagePath.contains('fail')) {
      await MockDelay.simulate(
          minMs: 600,
          maxMs: 1000,
          shouldFail: true,
          failureMessage: 'OCR parsing failed on unreadable image.');
    }

    // Typical OCR delay
    await MockDelay.simulate(minMs: 800, maxMs: 1400);

    return OcrResult(
      vendor: 'Sri Balaji Heavy Workshop, Sanath Nagar',
      billNo: 'INV-2026-B101',
      billDate: DateTime.now().subtract(const Duration(days: 2)),
      total: 14050.0,
      confidence: 0.94,
      rawLines: const [
        'SRI BALAJI HEAVY WORKSHOP',
        'SANATH NAGAR, HYDERABAD - 500018',
        'GSTIN: 36AAACB1234F1Z8',
        'INVOICE NO: INV-2026-B101',
        'CASTROL VECTON 15W-40 20L - Rs. 6800.00',
        'FLEETGUARD OIL FILTER - Rs. 1250.00',
        'DIESEL FUEL FILTERS (2) - Rs. 1700.00',
        'LABOUR CHARGES - Rs. 2500.00',
        'GST 18% - Rs. 1800.00',
        'TOTAL AMOUNT: Rs. 14050.00',
      ],
    );
  }
}
