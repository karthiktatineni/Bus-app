import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/service_repository.dart';
import 'data/supabase_service_repository.dart';
import '../../core/services/supabase_service.dart';

export 'domain/service_record.dart';
export 'domain/maintenance_task.dart';
export 'domain/service_schedule.dart';
export 'domain/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return SupabaseServiceRepository(ref.watch(supabaseClientProvider));
});
