import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/bill.dart';
import 'domain/bill_repository.dart';
import 'domain/ocr_service.dart';
import 'data/supabase_bill_repository.dart';
import 'data/render_cloud_ocr_service.dart';
import '../../core/services/supabase_service.dart';

export 'domain/bill.dart';
export 'domain/bill_repository.dart';
export 'domain/ocr_service.dart';

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return SupabaseBillRepository(ref.watch(supabaseClientProvider));
});

final billsListProvider = FutureProvider<List<Bill>>((ref) {
  return ref.watch(billRepositoryProvider).listAll();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  return RenderCloudOcrService();
});
