import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/service_repository.dart';
import 'data/mock_service_repository.dart';

export 'domain/service_record.dart';
export 'domain/maintenance_task.dart';
export 'domain/service_schedule.dart';
export 'domain/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return MockServiceRepository();
});
