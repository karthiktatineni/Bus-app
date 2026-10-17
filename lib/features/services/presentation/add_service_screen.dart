import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../vehicles/providers.dart';
import '../../bills/providers.dart';
import '../providers.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  final String? preselectedVehicleId;

  const AddServiceScreen({
    super.key,
    this.preselectedVehicleId,
  });

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Details
  String? _selectedVehicleId;
  ServiceType _serviceType = ServiceType.regular;
  DateTime _serviceDate = DateTime.now();
  final _odometerController = TextEditingController();
  final _workshopController = TextEditingController();
  final _mechanicController = TextEditingController();

  // Step 2: Parts & Costs
  final _labourCostController = TextEditingController();
  final List<Map<String, dynamic>> _parts = [];

  // Step 3: Photos
  final Map<PhotoType, List<String>> _photos = {
    for (final type in PhotoType.values) type: [],
  };

  // Step 4: Bill OCR
  bool _isScanningBill = false;
  bool _billScanned = false;
  final _vendorController = TextEditingController();
  final _billNoController = TextEditingController();
  final _billTotalController = TextEditingController();
  String? _billImagePath;
  DateTime? _billDate;
  double? _ocrConfidence;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.preselectedVehicleId;
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _workshopController.dispose();
    _mechanicController.dispose();
    _labourCostController.dispose();
    _vendorController.dispose();
    _billNoController.dispose();
    _billTotalController.dispose();
    super.dispose();
  }

  int get _partsTotal => _parts.fold<int>(
      0, (sum, p) => sum + ((p['cost'] as int) * (p['qty'] as int)));
  int get _labourTotal => int.tryParse(_labourCostController.text.trim()) ?? 0;
  int get _subtotal => _partsTotal + _labourTotal;
  int get _tax => (_subtotal * 0.18).round();
  int get _grandTotal => _subtotal + _tax;

  Future<void> _scanBill() async {
    final media = ref.read(mediaServiceProvider);
    final path =
        await media.pickImageFromCamera() ?? await media.pickImageFromGallery();
    if (path == null || !mounted) return;
    setState(() {
      _isScanningBill = true;
      _billImagePath = path;
    });
    try {
      final imagePath = await media.compressImage(path);
      final result = await ref.read(ocrServiceProvider).scanBill(imagePath);
      if (!mounted) return;
      setState(() {
        _isScanningBill = false;
        _billScanned = true;
        _ocrConfidence = result.confidence;
        _vendorController.text = result.vendor ?? '';
        _billNoController.text = result.billNo ?? '';
        _billTotalController.text = result.total?.toStringAsFixed(2) ?? '';
        _billDate = result.billDate;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isScanningBill = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not scan bill: $error')),
      );
    }
  }

  Future<void> _addPhoto(PhotoType type) async {
    final media = ref.read(mediaServiceProvider);
    final path =
        await media.pickImageFromCamera() ?? await media.pickImageFromGallery();
    if (path == null || !mounted) return;
    final imagePath = await media.compressImage(path);
    if (mounted) setState(() => _photos[type]!.add(imagePath));
  }

  Future<void> _submitService() async {
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isLoading = true);

    final record = ServiceRecord(
      id: const Uuid().v4(),
      vehicleId: _selectedVehicleId!,
      type: _serviceType,
      date: _serviceDate,
      odometerKm: int.tryParse(_odometerController.text.trim()) ?? 0,
      workshop: _workshopController.text.trim(),
      mechanic: _mechanicController.text.trim(),
      notes: 'Logged via mobile client',
      parts: _parts.map((part) {
        final quantity = part['qty'] as int;
        final unitCost = part['cost'] as int;
        return ServicePart(
          id: const Uuid().v4(),
          name: part['name'] as String,
          quantity: quantity,
          costPerUnit: unitCost.toDouble(),
          totalCost: (quantity * unitCost).toDouble(),
        );
      }).toList(),
      labourCost: _labourTotal.toDouble(),
      tax: _tax.toDouble(),
      total: _grandTotal.toDouble(),
      photos: _photos.entries
          .expand((entry) => entry.value.map((path) => ServicePhoto(
                id: const Uuid().v4(),
                url: path,
                type: entry.key,
              )))
          .toList(),
    );

    final serviceRepo = ref.read(serviceRepositoryProvider);
    try {
      final saved = await serviceRepo.create(record);
      final billTotal = double.tryParse(_billTotalController.text.trim());
      if (_vendorController.text.trim().isNotEmpty &&
          _billNoController.text.trim().isNotEmpty &&
          billTotal != null) {
        await ref.read(billRepositoryProvider).create(Bill(
              id: const Uuid().v4(),
              vehicleId: saved.vehicleId,
              serviceId: saved.id,
              vendor: _vendorController.text.trim(),
              billNo: _billNoController.text.trim(),
              billDate: _billDate ?? DateTime.now(),
              tax: saved.tax,
              total: billTotal,
              imageUrl: _billImagePath,
              ocrConfidence: _ocrConfidence,
            ));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save service record: $error')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Service record logged and scheduled next cycle advanced!'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleRepo = ref.watch(vehicleRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service Record'),
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: vehicleRepo.list(),
        builder: (context, snapshot) {
          final vehicles = snapshot.data ?? [];
          if (_selectedVehicleId == null && vehicles.isNotEmpty) {
            _selectedVehicleId = vehicles.first.id;
          }

          return Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              if (_currentStep < 3) {
                setState(() => _currentStep += 1);
              } else {
                _submitService();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              } else {
                context.pop();
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_currentStep == 3
                                ? 'Review & Save'
                                : 'Continue'),
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Details
              Step(
                title: const Text('Details'),
                isActive: _currentStep >= 0,
                state:
                    _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVehicleId,
                      decoration: const InputDecoration(
                          labelText: 'Select Bus / Vehicle *'),
                      items: vehicles
                          .map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text('${v.registrationNo} (${v.make})'),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedVehicleId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ServiceType>(
                      initialValue: _serviceType,
                      decoration:
                          const InputDecoration(labelText: 'Service Type *'),
                      items: ServiceType.values
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t.label)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _serviceType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _odometerController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Odometer (km) *',
                              suffixText: 'KM',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _serviceDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _serviceDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                  labelText: 'Service Date'),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_serviceDate),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _workshopController,
                      decoration: const InputDecoration(
                          labelText: 'Workshop / Vendor *'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mechanicController,
                      decoration: const InputDecoration(
                          labelText: 'Assigned Mechanic / Lead'),
                    ),
                  ],
                ),
              ),

              // Step 2: Parts & Costs
              Step(
                title: const Text('Parts'),
                isActive: _currentStep >= 1,
                state:
                    _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Replaced Parts',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Part'),
                          onPressed: () {
                            setState(() {
                              _parts.add({
                                'name': 'New Part / Seal',
                                'qty': 1,
                                'cost': 850
                              });
                            });
                          },
                        ),
                      ],
                    ),
                    ..._parts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: p['name'] as String,
                                decoration:
                                    const InputDecoration(isDense: true),
                                onChanged: (val) => p['name'] = val,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: p['qty'].toString(),
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(isDense: true),
                                onChanged: (val) => setState(
                                    () => p['qty'] = int.tryParse(val) ?? 1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: p['cost'].toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    isDense: true, prefixText: '₹'),
                                onChanged: (val) => setState(
                                    () => p['cost'] = int.tryParse(val) ?? 0),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppTheme.danger),
                              onPressed: () =>
                                  setState(() => _parts.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _labourCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Labour Charges (₹)'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Parts Total:'),
                              Text(
                                  '₹${NumberFormat('#,###').format(_partsTotal)}',
                                  style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Labour:'),
                              Text(
                                  '₹${NumberFormat('#,###').format(_labourTotal)}',
                                  style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GST (18%):'),
                              Text('₹${NumberFormat('#,###').format(_tax)}',
                                  style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '₹${NumberFormat('#,###').format(_grandTotal)}',
                                  style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.primaryColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Step 3: Photos
              Step(
                title: const Text('Photos'),
                isActive: _currentStep >= 2,
                state:
                    _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Inspection Photos',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    _photoRow('Before Service', PhotoType.before),
                    const SizedBox(height: 8),
                    _photoRow('After Service', PhotoType.after),
                    const SizedBox(height: 8),
                    _photoRow('Replaced Parts', PhotoType.part),
                  ],
                ),
              ),

              // Step 4: Bill OCR & Review
              Step(
                title: const Text('Bill & Save'),
                isActive: _currentStep >= 3,
                state: StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock OCR Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.document_scanner,
                                        color: AppTheme.primaryColor),
                                    SizedBox(width: 8),
                                    Text('Bill OCR Scanner',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ],
                                ),
                                if (_billScanned)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'OCR ${((_ocrConfidence ?? 0) * 100).round()}% CONFIDENCE',
                                      style: const TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.success),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Capture a bill image and confirm any low-confidence fields before saving.',
                              style: TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: _isScanningBill
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.camera_alt),
                                label: Text(_billScanned
                                    ? 'Rescan Invoice'
                                    : 'Scan Bill / Invoice'),
                                onPressed: _isScanningBill ? null : _scanBill,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _vendorController,
                      decoration: InputDecoration(
                        labelText: 'Vendor Name',
                        suffixIcon: _confidenceIcon,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _billNoController,
                      decoration: InputDecoration(
                        labelText: 'Invoice / Bill Number',
                        suffixIcon: _confidenceIcon,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _billTotalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Billed Amount (₹)',
                        prefixText: '₹',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _photoRow(String title, PhotoType type) {
    final count = _photos[type]!.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(count > 0 ? Icons.check_circle : Icons.add_a_photo_outlined,
                  color: count > 0 ? AppTheme.success : AppTheme.primaryColor,
                  size: 20),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          TextButton(
            onPressed: () => _addPhoto(type),
            child: Text(count > 0 ? '$count added · Capture' : 'Capture'),
          ),
        ],
      ),
    );
  }

  Widget? get _confidenceIcon => !_billScanned
      ? null
      : Tooltip(
          message: (_ocrConfidence ?? 0) < 0.85
              ? 'Check this field'
              : 'Extracted via OCR',
          child: Icon(
            (_ocrConfidence ?? 0) < 0.85
                ? Icons.warning_amber
                : Icons.check_circle,
            color:
                (_ocrConfidence ?? 0) < 0.85 ? Colors.amber : AppTheme.success,
            size: 18,
          ),
        );
}
