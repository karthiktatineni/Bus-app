import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_media_storage.dart';

import '../domain/bill.dart';
import '../domain/bill_repository.dart';

class SupabaseBillRepository implements BillRepository {
  SupabaseBillRepository(this._client);

  final SupabaseClient _client;
  late final SupabaseMediaStorage _storage = SupabaseMediaStorage(_client);

  Future<String> _companyId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in before accessing bills.');
    final row = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', user.id)
        .single();
    return row['company_id'] as String;
  }

  @override
  Future<List<Bill>> listAll({String? vehicleId}) async {
    var query = _client.from('bills').select();
    if (vehicleId != null) query = query.eq('vehicle_id', vehicleId);
    final rows = await query.order('bill_date', ascending: false);
    final creatorIds = rows
        .map((row) => row['created_by'])
        .whereType<String>()
        .toSet()
        .toList();
    final uploaderNames = <String, String>{};
    if (creatorIds.isNotEmpty) {
      final profiles = await _client
          .from('profiles')
          .select('id,name')
          .inFilter('id', creatorIds);
      for (final profile in profiles) {
        final id = profile['id'] as String?;
        final name = profile['name'] as String?;
        if (id != null && name != null && name.isNotEmpty) {
          uploaderNames[id] = name;
        }
      }
    }
    return Future.wait(rows.map((row) async => _fromRow(
          row,
          uploaderName: uploaderNames[row['created_by']],
          items: await _client
              .from('bill_items')
              .select()
              .eq('bill_id', row['id']),
        )));
  }

  @override
  Future<Bill> get(String id) async {
    final row = await _client.from('bills').select().eq('id', id).single();
    final items = await _client.from('bill_items').select().eq('bill_id', id);
    return _fromRow(
      row,
      items: items,
      uploaderName: await _getUploaderName(row['created_by'] as String?),
    );
  }

  @override
  Future<Bill> create(Bill bill) async {
    final user = _client.auth.currentUser;
    final companyId = await _companyId();
    var imageUrl = bill.imageUrl;
    if (imageUrl != null && File(imageUrl).existsSync()) {
      imageUrl = await _storage.upload(
        bucket: 'bills',
        companyId: companyId,
        parentId: bill.vehicleId,
        filePath: imageUrl,
      );
    }
    final row = await _client
        .from('bills')
        .insert({
          'company_id': companyId,
          'vehicle_id': bill.vehicleId,
          'service_id': bill.serviceId.isEmpty ? null : bill.serviceId,
          'vendor': bill.vendor,
          'bill_no': bill.billNo,
          'bill_date': _date(bill.billDate),
          'tax': bill.tax,
          'total': bill.total,
          'image_url': imageUrl,
          'ocr_confidence': bill.ocrConfidence,
          'created_by': user?.id,
        })
        .select()
        .single();
    try {
      if (bill.items.isNotEmpty) {
        await _client.from('bill_items').insert(bill.items
            .map((item) => {
                  'company_id': companyId,
                  'bill_id': row['id'],
                  'name': item.name,
                  'qty': item.quantity,
                  'cost': item.total,
                })
            .toList());
      }
    } catch (_) {
      await _client.from('bills').delete().eq('id', row['id']);
      rethrow;
    }
    return get(row['id'] as String);
  }

  @override
  Future<Bill> update(Bill bill) async {
    final companyId = await _companyId();
    final existing = await _client
        .from('bills')
        .select('image_url')
        .eq('id', bill.id)
        .single();
    final existingImage = existing['image_url'] as String?;
    var imageUrl = existingImage;
    final suppliedImage = bill.imageUrl;
    if (suppliedImage == null) {
      imageUrl = null;
    } else if (File(suppliedImage).existsSync()) {
      imageUrl = await _storage.upload(
        bucket: 'bills',
        companyId: companyId,
        parentId: bill.vehicleId,
        filePath: suppliedImage,
      );
    }
    await _client.from('bills').update({
      'vehicle_id': bill.vehicleId,
      'service_id': bill.serviceId.isEmpty ? null : bill.serviceId,
      'vendor': bill.vendor,
      'bill_no': bill.billNo,
      'bill_date': _date(bill.billDate),
      'tax': bill.tax,
      'total': bill.total,
      'image_url': imageUrl,
      'ocr_confidence': bill.ocrConfidence,
    }).eq('id', bill.id);
    await _client.from('bill_items').delete().eq('bill_id', bill.id);
    if (bill.items.isNotEmpty) {
      await _client.from('bill_items').insert(bill.items
          .map((item) => {
                'company_id': companyId,
                'bill_id': bill.id,
                'name': item.name,
                'qty': item.quantity,
                'cost': item.total,
              })
          .toList());
    }
    return get(bill.id);
  }

  @override
  Future<void> delete(String id) async {
    final row = await _client
        .from('bills')
        .select('image_url')
        .eq('id', id)
        .maybeSingle();
    final storedImage = row?['image_url'] as String?;
    if (storedImage != null &&
        !storedImage.startsWith('http://') &&
        !storedImage.startsWith('https://')) {
      await _storage.remove('bills', storedImage);
    }
    await _client.from('bills').delete().eq('id', id);
  }

  @override
  Future<void> deleteImage(String id) async {
    final row = await _client
        .from('bills')
        .select('image_url')
        .eq('id', id)
        .maybeSingle();
    final storedImage = row?['image_url'] as String?;
    if (storedImage == null) return;

    if (!storedImage.startsWith('http://') &&
        !storedImage.startsWith('https://')) {
      await _storage.remove('bills', storedImage);
    }
    await _client.from('bills').update({'image_url': null}).eq('id', id);
  }

  Future<String?> _getUploaderName(String? userId) async {
    if (userId == null) return null;
    final row = await _client
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .maybeSingle();
    final name = row?['name'] as String?;
    return name == null || name.isEmpty ? null : name;
  }

  Future<Bill> _fromRow(Map<String, dynamic> row,
      {List<Map<String, dynamic>> items = const [], String? uploaderName}) {
    return _fromRowAsync(row, items: items, uploaderName: uploaderName);
  }

  Future<Bill> _fromRowAsync(Map<String, dynamic> row,
      {List<Map<String, dynamic>> items = const [],
      String? uploaderName}) async {
    final storedImage = row['image_url'] as String?;
    final image = storedImage == null
        ? null
        : await _storage.signedUrl('bills', storedImage);
    return Bill(
      id: row['id'] as String,
      vehicleId: row['vehicle_id'] as String,
      serviceId: row['service_id'] as String? ?? '',
      vendor: row['vendor'] as String? ?? '',
      billNo: row['bill_no'] as String? ?? '',
      billDate: DateTime.parse(row['bill_date'] as String),
      items: items.map((item) {
        final qty = (item['qty'] as num).toDouble();
        final total = (item['cost'] as num).toDouble();
        return BillItem(
            name: item['name'] as String,
            quantity: qty.round(),
            unitCost: qty == 0 ? 0 : total / qty,
            total: total);
      }).toList(),
      tax: (row['tax'] as num).toDouble(),
      total: (row['total'] as num).toDouble(),
      imageUrl: image,
      ocrConfidence: (row['ocr_confidence'] as num?)?.toDouble(),
      uploaderName: uploaderName,
    );
  }

  String _date(DateTime date) => date.toIso8601String().split('T').first;
}
