import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_media_storage.dart';
import '../domain/vehicle.dart';
import '../domain/vehicle_repository.dart';
import '../domain/vehicle_status.dart';
import '../domain/vehicle_document.dart';

class SupabaseVehicleRepository implements VehicleRepository {
  final SupabaseClient _client;
  late final SupabaseMediaStorage _storage = SupabaseMediaStorage(_client);

  SupabaseVehicleRepository(this._client);

  Future<String> _getCompanyId() async {
    final profile = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', _client.auth.currentUser!.id)
        .single();
    return profile['company_id'] as String;
  }

  @override
  Future<List<Vehicle>> list() async {
    final rows = await _client
        .from('vehicles')
        .select()
        .isFilter('deleted_at', null)
        .order('registration_no');

    return _hydrateRows(rows);
  }

  @override
  Stream<List<Vehicle>> watch() {
    // Realtime is enabled for public.vehicles by migration 20261017030000.
    // Keep soft-deleted rows in the stream so their updates remove them from
    // this list immediately; company visibility remains enforced by RLS.
    return _client
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .order('registration_no')
        .asyncMap(_hydrateRows);
  }

  Future<List<Vehicle>> _hydrateRows(List<Map<String, dynamic>> allRows) async {
    final rows = allRows.where((row) => row['deleted_at'] == null).toList();
    if (rows.isEmpty) return const [];

    final ids = rows.map((row) => row['id'] as String).toList();
    final related = await Future.wait([
      _client.from('vehicle_documents').select().inFilter('vehicle_id', ids),
      _client.from('vehicle_photos').select().inFilter('vehicle_id', ids),
    ]);
    final documentsByVehicle = <String, List<Map<String, dynamic>>>{};
    for (final document in related[0]) {
      (documentsByVehicle[document['vehicle_id'] as String] ??= [])
          .add(document);
    }
    final photosByVehicle = <String, List<Map<String, dynamic>>>{};
    for (final photo in related[1]) {
      (photosByVehicle[photo['vehicle_id'] as String] ??= []).add(photo);
    }

    return Future.wait(rows.map((row) => _rowToVehicle(
          row,
          documents: documentsByVehicle[row['id'] as String] ?? const [],
          photoRows: photosByVehicle[row['id'] as String] ?? const [],
        )));
  }

  @override
  Future<Vehicle> get(String id) async {
    final row = await _client.from('vehicles').select().eq('id', id).single();
    final docs =
        await _client.from('vehicle_documents').select().eq('vehicle_id', id);
    final photos =
        await _client.from('vehicle_photos').select().eq('vehicle_id', id);
    return _rowToVehicle(row, documents: docs, photoRows: photos);
  }

  @override
  Future<Vehicle> create(Vehicle v) async {
    final companyId = await _getCompanyId();
    final row = await _client
        .from('vehicles')
        .insert({
          'company_id': companyId,
          'registration_no': v.registrationNo,
          'make': v.make,
          'model': v.model,
          'year': v.year,
          'chassis_no': v.chassisNo,
          'engine_no': v.engineNo,
          'seats': v.seats,
          'fuel_type': v.fuelType,
          'odometer_km': v.odometerKm,
          'depot': v.depot,
          'purchase_date': v.purchaseDate.toIso8601String().split('T').first,
          'status': v.status.name,
          'created_by': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    for (final path in v.photos.where((path) => File(path).existsSync())) {
      final objectPath = await _storage.upload(
          bucket: 'vehicle-photos',
          companyId: companyId,
          parentId: row['id'] as String,
          filePath: path);
      await _client.from('vehicle_photos').insert({
        'company_id': companyId,
        'vehicle_id': row['id'],
        'url': objectPath,
        'created_by': _client.auth.currentUser!.id,
      });
    }
    for (final document in v.documents) {
      await _client.from('vehicle_documents').insert({
        'company_id': companyId,
        'vehicle_id': row['id'],
        'type': document.type.name,
        'number': document.number,
        'expiry_date': document.expiryDate.toIso8601String().split('T').first,
        'file_url': document.fileUrl,
        'created_by': _client.auth.currentUser!.id,
      });
    }
    return get(row['id'] as String);
  }

  @override
  Future<Vehicle> update(Vehicle v) async {
    final row = await _client
        .from('vehicles')
        .update({
          'registration_no': v.registrationNo,
          'make': v.make,
          'model': v.model,
          'year': v.year,
          'chassis_no': v.chassisNo,
          'engine_no': v.engineNo,
          'seats': v.seats,
          'fuel_type': v.fuelType,
          'odometer_km': v.odometerKm,
          'depot': v.depot,
          'purchase_date': v.purchaseDate.toIso8601String().split('T').first,
          'status': v.status.name,
        })
        .eq('id', v.id)
        .select()
        .single();
    return _rowToVehicle(row);
  }

  @override
  Future<void> delete(String id) async {
    // Soft delete
    await _client.from('vehicles').update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<Vehicle> _rowToVehicle(
    Map<String, dynamic> row, {
    List<Map<String, dynamic>>? documents,
    List<Map<String, dynamic>>? photoRows,
  }) async {
    return Vehicle(
      id: row['id'] as String,
      registrationNo: row['registration_no'] as String,
      make: row['make'] as String,
      model: row['model'] as String,
      year: row['year'] as int,
      chassisNo: row['chassis_no'] as String? ?? '',
      engineNo: row['engine_no'] as String? ?? '',
      seats: row['seats'] as int? ?? 40,
      fuelType: row['fuel_type'] as String? ?? 'Diesel',
      odometerKm: row['odometer_km'] as int? ?? 0,
      depot: row['depot'] as String? ?? '',
      purchaseDate: row['purchase_date'] != null
          ? DateTime.parse(row['purchase_date'] as String)
          : DateTime.now(),
      status: VehicleStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => VehicleStatus.active,
      ),
      photos: await Future.wait((photoRows ?? const []).map((photo) =>
          _storage.signedUrl('vehicle-photos', photo['url'] as String))),
      documents: documents
              ?.map((d) => VehicleDocument(
                    id: d['id'] as String,
                    type: DocumentType.values.firstWhere(
                      (type) => type.name == d['type'],
                      orElse: () => DocumentType.insurance,
                    ),
                    number: d['number'] as String,
                    expiryDate: DateTime.parse(d['expiry_date'] as String),
                    fileUrl: d['file_url'] as String?,
                  ))
              .toList() ??
          const [],
    );
  }
}
