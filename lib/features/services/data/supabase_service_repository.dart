import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_media_storage.dart';
import '../domain/service_record.dart';
import '../domain/service_repository.dart';
import '../domain/maintenance_task.dart';
import '../domain/service_schedule.dart';

class SupabaseServiceRepository implements ServiceRepository {
  final SupabaseClient _client;
  late final SupabaseMediaStorage _storage = SupabaseMediaStorage(_client);

  SupabaseServiceRepository(this._client);

  Future<String> _getCompanyId() async {
    final profile = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', _client.auth.currentUser!.id)
        .single();
    return profile['company_id'] as String;
  }

  @override
  Future<List<ServiceRecord>> listAll({String? vehicleId}) async {
    var query = _client.from('service_records').select();
    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }
    final rows = await query.order('date', ascending: false);

    final billIdsByService = <String, String>{};
    if (rows.isNotEmpty) {
      final linkedBills = await _client
          .from('bills')
          .select('id,service_id')
          .inFilter('service_id', rows.map((row) => row['id']).toList());
      for (final bill in linkedBills) {
        final serviceId = bill['service_id'] as String?;
        final billId = bill['id'] as String?;
        if (serviceId != null && billId != null) {
          billIdsByService[serviceId] = billId;
        }
      }
    }

    final records = <ServiceRecord>[];
    for (final row in rows) {
      final parts = await _client
          .from('service_parts')
          .select()
          .eq('service_record_id', row['id']);
      final photos = await _client
          .from('service_photos')
          .select()
          .eq('service_record_id', row['id']);
      records.add(await _rowToServiceRecord(
        row,
        parts: parts,
        photos: photos,
        billId: billIdsByService[row['id'] as String],
      ));
    }
    return records;
  }

  @override
  Future<ServiceRecord> get(String id) async {
    final row =
        await _client.from('service_records').select().eq('id', id).single();
    final parts = await _client
        .from('service_parts')
        .select()
        .eq('service_record_id', id);
    final photos = await _client
        .from('service_photos')
        .select()
        .eq('service_record_id', id);
    final bill = await _client
        .from('bills')
        .select('id')
        .eq('service_id', id)
        .maybeSingle();
    return _rowToServiceRecord(
      row,
      parts: parts,
      photos: photos,
      billId: bill?['id'] as String?,
    );
  }

  @override
  Future<ServiceRecord> create(ServiceRecord r) async {
    final companyId = await _getCompanyId();
    final row = await _client
        .from('service_records')
        .insert({
          'company_id': companyId,
          'vehicle_id': r.vehicleId,
          'type': r.type.label,
          'date': r.date.toIso8601String().split('T').first,
          'odometer_km': r.odometerKm,
          'workshop': r.workshop,
          'mechanic': r.mechanic,
          'notes': r.notes,
          'labour_cost': r.labourCost,
          'tax': r.tax,
          'total': r.total,
          'created_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();

    // Insert parts
    for (final part in r.parts) {
      await _client.from('service_parts').insert({
        'company_id': companyId,
        'service_record_id': row['id'],
        'name': part.name,
        'qty': part.quantity,
        'cost': part.totalCost,
      });
    }

    for (final photo in r.photos) {
      var storedUrl = photo.url;
      if (File(photo.url).existsSync()) {
        storedUrl = await _storage.upload(
          bucket: 'service-photos',
          companyId: companyId,
          parentId: row['id'] as String,
          filePath: photo.url,
        );
      }
      await _client.from('service_photos').insert({
        'company_id': companyId,
        'service_record_id': row['id'],
        'url': storedUrl,
        'type': photo.type.name,
        'caption': photo.caption,
        'part_id': photo.partId,
      });
    }

    return _rowToServiceRecord(row);
  }

  @override
  Future<void> delete(String id) async {
    final photos = await _client
        .from('service_photos')
        .select('url')
        .eq('service_record_id', id);
    for (final photo in photos) {
      final path = photo['url'] as String?;
      if (path != null &&
          !path.startsWith('http://') &&
          !path.startsWith('https://')) {
        await _storage.remove('service-photos', path);
      }
    }
    await _client.from('service_records').delete().eq('id', id);
  }

  @override
  Future<void> deletePhoto(String serviceId, String photoId) async {
    final photo = await _client
        .from('service_photos')
        .select('url')
        .eq('id', photoId)
        .eq('service_record_id', serviceId)
        .maybeSingle();
    if (photo == null) return;

    final path = photo['url'] as String?;
    if (path != null &&
        !path.startsWith('http://') &&
        !path.startsWith('https://')) {
      await _storage.remove('service-photos', path);
    }
    await _client
        .from('service_photos')
        .delete()
        .eq('id', photoId)
        .eq('service_record_id', serviceId);
  }

  @override
  Future<void> addPhoto(
      String serviceId, String filePath, PhotoType type) async {
    final companyId = await _getCompanyId();
    final objectPath = await _storage.upload(
      bucket: 'service-photos',
      companyId: companyId,
      parentId: serviceId,
      filePath: filePath,
    );
    await _client.from('service_photos').insert({
      'company_id': companyId,
      'service_record_id': serviceId,
      'url': objectPath,
      'type': type.name,
    });
  }

  @override
  Future<List<MaintenanceTask>> upcomingTasks({int withinDays = 14}) async {
    final rows = await _client
        .from('maintenance_tasks')
        .select('*, vehicles!inner(registration_no, make, model)')
        .eq('is_done', false)
        .lte(
            'due_date',
            DateTime.now()
                .add(Duration(days: withinDays))
                .toIso8601String()
                .split('T')
                .first)
        .order('due_date');
    return rows.map(_rowToMaintenanceTask).toList();
  }

  @override
  Future<MaintenanceTask> createTask(MaintenanceTask task) async {
    final companyId = await _getCompanyId();
    final row = await _client
        .from('maintenance_tasks')
        .insert({
          'company_id': companyId,
          'vehicle_id': task.vehicleId,
          'title': task.title,
          'due_date': task.dueDate?.toIso8601String().split('T').first,
          'due_km': task.dueKm,
          'schedule_id': task.scheduleId,
          'service_record_id': task.serviceRecordId,
          'created_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return _rowToMaintenanceTask(row);
  }

  @override
  Future<void> setTaskDone(String taskId, bool done) async {
    await _client.from('maintenance_tasks').update({
      'is_done': done,
      'completed_at': done ? DateTime.now().toUtc().toIso8601String() : null,
      'completed_by': done ? _client.auth.currentUser!.id : null,
    }).eq('id', taskId);
  }

  @override
  Future<List<ServiceSchedule>> listSchedules({String? vehicleId}) async {
    var query = _client.from('service_schedules').select();
    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }
    final rows = await query.order('task_name');
    return rows.map(_rowToServiceSchedule).toList();
  }

  @override
  Future<ServiceSchedule> createSchedule(ServiceSchedule s) async {
    final companyId = await _getCompanyId();
    final row = await _client
        .from('service_schedules')
        .insert({
          'company_id': companyId,
          'vehicle_id': s.vehicleId,
          'task_name': s.taskName,
          'interval_km': s.intervalKm,
          'interval_months': s.intervalMonths,
          'last_done_date': s.lastDoneDate.toIso8601String().split('T').first,
          'last_done_km': s.lastDoneKm,
          'created_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return _rowToServiceSchedule(row);
  }

  @override
  Future<ServiceSchedule> updateSchedule(ServiceSchedule s) async {
    final row = await _client
        .from('service_schedules')
        .update({
          'task_name': s.taskName,
          'interval_km': s.intervalKm,
          'interval_months': s.intervalMonths,
          'last_done_date': s.lastDoneDate.toIso8601String().split('T').first,
          'last_done_km': s.lastDoneKm,
        })
        .eq('id', s.id)
        .select()
        .single();
    return _rowToServiceSchedule(row);
  }

  Future<ServiceRecord> _rowToServiceRecord(
    Map<String, dynamic> row, {
    List<Map<String, dynamic>>? parts,
    List<Map<String, dynamic>>? photos,
    String? billId,
  }) async {
    return ServiceRecord(
      id: row['id'] as String,
      vehicleId: row['vehicle_id'] as String,
      type: ServiceType.values.firstWhere(
        (t) => t.label == row['type'] || t.name == row['type'],
        orElse: () => ServiceType.regular,
      ),
      date: DateTime.parse(row['date'] as String),
      odometerKm: row['odometer_km'] as int,
      workshop: row['workshop'] as String,
      mechanic: row['mechanic'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
      parts: parts
              ?.map((p) => ServicePart(
                    id: p['id'] as String,
                    name: p['name'] as String,
                    quantity: (p['qty'] as num).toInt(),
                    costPerUnit: (p['cost'] as num).toDouble(),
                    totalCost: (p['cost'] as num).toDouble() *
                        (p['qty'] as num).toDouble(),
                  ))
              .toList() ??
          const [],
      labourCost: (row['labour_cost'] as num).toDouble(),
      tax: (row['tax'] as num).toDouble(),
      total: (row['total'] as num).toDouble(),
      billId: billId,
      photos: photos == null
          ? const []
          : await Future.wait(photos.map((p) async => ServicePhoto(
                id: p['id'] as String,
                url: await _storage.signedUrl(
                    'service-photos', p['url'] as String),
                type: PhotoType.values.firstWhere(
                  (t) => t.name == p['type'],
                  orElse: () => PhotoType.part,
                ),
                caption: p['caption'] as String?,
                partId: p['part_id'] as String?,
              ))),
    );
  }

  MaintenanceTask _rowToMaintenanceTask(Map<String, dynamic> row) {
    return MaintenanceTask(
      id: row['id'] as String,
      vehicleId: row['vehicle_id'] as String,
      scheduleId: row['schedule_id'] as String?,
      title: row['title'] as String,
      dueDate: row['due_date'] != null
          ? DateTime.parse(row['due_date'] as String)
          : null,
      dueKm: row['due_km'] as int?,
      isDone: row['is_done'] as bool? ?? false,
      completedAt: row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : null,
      serviceRecordId: row['service_record_id'] as String?,
    );
  }

  ServiceSchedule _rowToServiceSchedule(Map<String, dynamic> row) {
    return ServiceSchedule(
      id: row['id'] as String,
      vehicleId: row['vehicle_id'] as String,
      taskName: row['task_name'] as String,
      intervalKm: row['interval_km'] as int? ?? 0,
      intervalMonths: row['interval_months'] as int? ?? 0,
      lastDoneDate: row['last_done_date'] != null
          ? DateTime.parse(row['last_done_date'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      lastDoneKm: row['last_done_km'] as int? ?? 0,
    );
  }
}
