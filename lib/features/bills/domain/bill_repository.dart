import 'bill.dart';

abstract class BillRepository {
  Future<List<Bill>> listAll({String? vehicleId});
  Future<Bill> get(String id);
  Future<Bill> create(Bill b);
  Future<Bill> update(Bill b);
  Future<void> delete(String id);
  Future<void> deleteImage(String id);
}
