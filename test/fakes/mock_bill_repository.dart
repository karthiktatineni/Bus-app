import 'package:bus_app/core/errors/app_exception.dart';
import 'package:bus_app/features/bills/domain/bill.dart';
import 'package:bus_app/features/bills/domain/bill_repository.dart';
import 'mock_data.dart';
import 'mock_delay.dart';

class MockBillRepository implements BillRepository {
  late final List<Bill> _bills;

  MockBillRepository() {
    final services = MockData.generateServiceRecords();
    _bills = MockData.generateBills(services);
  }

  @override
  Future<List<Bill>> listAll({String? vehicleId}) async {
    await MockDelay.simulate();
    if (vehicleId != null) {
      return _bills.where((b) => b.vehicleId == vehicleId).toList();
    }
    return List.unmodifiable(_bills);
  }

  @override
  Future<Bill> get(String id) async {
    if (id == 'fail-id' || id == 'bill-error') {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Simulated bill retrieval error.');
    }

    await MockDelay.simulate();
    return _bills.firstWhere(
      (b) => b.id == id,
      orElse: () => throw NotFoundException('Bill with ID $id not found.'),
    );
  }

  @override
  Future<Bill> create(Bill b) async {
    if (b.vendor.contains('FAIL')) {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Simulated bill creation error.');
    }

    await MockDelay.simulate();
    _bills.insert(0, b);
    return b;
  }

  @override
  Future<Bill> update(Bill b) async {
    if (b.id == 'fail-id') {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Simulated bill update error.');
    }

    await MockDelay.simulate();
    final index = _bills.indexWhere((item) => item.id == b.id);
    if (index == -1) {
      throw NotFoundException('Bill with ID ${b.id} not found.');
    }
    _bills[index] = b;
    return b;
  }

  @override
  Future<void> delete(String id) async {
    if (id == 'fail-id') {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Simulated bill deletion error.');
    }

    await MockDelay.simulate();
    final index = _bills.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw NotFoundException('Bill with ID $id not found.');
    }
    _bills.removeAt(index);
  }

  @override
  Future<void> deleteImage(String id) async {
    await MockDelay.simulate();
    final index = _bills.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw NotFoundException('Bill with ID $id not found.');
    }
    _bills[index] = _bills[index].copyWith(clearImageUrl: true);
  }
}
