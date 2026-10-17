import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
  final _notesController = TextEditingController();
  final _nextServiceTitleController = TextEditingController();
  final _nextDueKmController = TextEditingController();
  DateTime? _nextDueDate;

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
    _notesController.dispose();
    _nextServiceTitleController.dispose();
    _nextDueKmController.dispose();
    _labourCostController.dispose();
    _vendorController.dispose();
    _billNoController.dispose();
    _billTotalController.dispose();
    super.dispose();
  }

  double get _labourTotal =>
      double.tryParse(_labourCostController.text.trim()) ?? 0;

  Future<void> _scanBill() async {
    final media = ref.read(mediaServiceProvider);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take bill photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose bill photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final path = source == ImageSource.camera
        ? await media.pickImageFromCamera()
        : await media.pickImageFromGallery();
    if (path == null || !mounted) return;
    setState(() {
      _isScanningBill = true;
    });
    try {
      final imagePath = await media.compressImage(path);
      if (!mounted) return;
      setState(() => _billImagePath = imagePath);
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
    if (_isLoading) return;

    final nextServiceTitle = _nextServiceTitleController.text.trim();
    final nextDueKm = int.tryParse(_nextDueKmController.text.trim());
    if (nextServiceTitle.isEmpty || _nextDueDate == null) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the next service task and its due date.'),
        ),
      );
      return;
    }

    final hasServicePhoto = _photos.values.any((photos) => photos.isNotEmpty);
    if (!hasServicePhoto) {
      setState(() => _currentStep = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one service photo to continue.')),
      );
      return;
    }
    if (_billImagePath == null) {
      setState(() => _currentStep = 3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload a bill photo to continue.')),
      );
      return;
    }
    final billTotal = double.tryParse(_billTotalController.text.trim());
    if (billTotal == null || billTotal <= 0) {
      setState(() => _currentStep = 3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter the total amount shown on the bill.')),
      );
      return;
    }
    final billVendor = _vendorController.text.trim();
    if (billVendor.isEmpty) {
      setState(() => _currentStep = 3);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter the vendor name shown on the bill.')),
      );
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isLoading = true);

    final enteredParts = _parts
        .where((part) => (part['name'] as String).trim().isNotEmpty)
        .toList(growable: false);
    final record = ServiceRecord(
      id: const Uuid().v4(),
      vehicleId: _selectedVehicleId!,
      type: _serviceType,
      date: _serviceDate,
      odometerKm: int.tryParse(_odometerController.text.trim()) ?? 0,
      workshop: _workshopController.text.trim(),
      mechanic: _mechanicController.text.trim(),
      notes: _notesController.text.trim(),
      parts: enteredParts.map((part) {
        final quantity = part['qty'] as int;
        final unitCost = part['cost'] as double;
        return ServicePart(
          id: const Uuid().v4(),
          name: part['name'] as String,
          quantity: quantity,
          costPerUnit: unitCost,
          totalCost: quantity * unitCost,
        );
      }).toList(),
      labourCost: _labourTotal.toDouble(),
      tax: 0,
      total: billTotal,
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
      try {
        await ref.read(billRepositoryProvider).create(Bill(
              id: const Uuid().v4(),
              vehicleId: saved.vehicleId,
              serviceId: saved.id,
              vendor: billVendor,
              billNo: _billNoController.text.trim(),
              billDate: _billDate ?? DateTime.now(),
              items: enteredParts.map((part) {
                final quantity = part['qty'] as int;
                final unitCost = part['cost'] as double;
                return BillItem(
                  name: (part['name'] as String).trim(),
                  quantity: quantity,
                  unitCost: unitCost,
                  total: unitCost * quantity,
                );
              }).toList(),
              tax: 0,
              total: billTotal,
              imageUrl: _billImagePath,
              ocrConfidence: _ocrConfidence,
            ));
      } catch (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Service record saved, but the bill could not be saved: $error. Open the service record and add the bill again.'),
          duration: const Duration(seconds: 7),
        ));
        context.pop();
        return;
      }
      try {
        await ref.read(serviceRepositoryProvider).createTask(MaintenanceTask(
              id: const Uuid().v4(),
              vehicleId: saved.vehicleId,
              title: nextServiceTitle,
              dueDate: _nextDueDate,
              dueKm: nextDueKm,
              serviceRecordId: saved.id,
            ));
      } catch (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Service and bill saved, but the next-service reminder could not be saved: $error.'),
          duration: const Duration(seconds: 7),
        ));
        context.pop();
        return;
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
          content: Text('Service record, parts and attachments saved.'),
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
          final rawVehicles = snapshot.data ?? [];
          final vehiclesById = <String, Vehicle>{};
          for (final vehicle in rawVehicles) {
            vehiclesById.putIfAbsent(vehicle.id, () => vehicle);
          }
          final vehicles = vehiclesById.values.toList(growable: false);
          final vehicleIds = vehiclesById.keys.toSet();
          if (_selectedVehicleId == null ||
              !vehicleIds.contains(_selectedVehicleId)) {
            _selectedVehicleId = vehicles.isEmpty ? null : vehicles.first.id;
          }

          return Stepper(
            type: MediaQuery.sizeOf(context).width < 600
                ? StepperType.vertical
                : StepperType.horizontal,
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
                      key: ValueKey(vehicleIds.join('|')),
                      initialValue: _selectedVehicleId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Select Bus / Vehicle *'),
                      items: vehicles
                          .map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(
                                  '${v.registrationNo} (${v.make})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedVehicleId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ServiceType>(
                      initialValue: _serviceType,
                      isExpanded: true,
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Service details / work performed',
                        hintText: 'Describe inspection, repairs and findings',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Next service due',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nextServiceTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Next service / maintenance task *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _nextDueDate ??
                              _serviceDate.add(const Duration(days: 90)),
                          firstDate: _serviceDate,
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setState(() => _nextDueDate = selected);
                        }
                      },
                      icon: const Icon(Icons.event_outlined),
                      label: Text(_nextDueDate == null
                          ? 'Set next due date *'
                          : 'Due ${DateFormat('dd MMM yyyy').format(_nextDueDate!)}'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nextDueKmController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Next due odometer (optional)',
                        suffixText: 'km',
                      ),
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
                              _parts.add({'name': '', 'qty': 1, 'cost': 0.0});
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
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Part name',
                                ),
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
                                initialValue: (p['cost'] as double).toString(),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    isDense: true, prefixText: '₹'),
                                onChanged: (val) => setState(() =>
                                    p['cost'] = double.tryParse(val) ?? 0),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      child: const Text(
                        'Part and labour amounts are saved as entered. Enter the total printed on the bill in the next step; FleetPulse does not calculate the bill total or add GST.',
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
                    const SizedBox(height: 4),
                    const Text(
                      'Add at least one service photo. Parts are entered manually; OCR does not identify replaced parts.',
                      style: TextStyle(fontSize: 11),
                    ),
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
                              'Take or choose an invoice photo. OCR reads vendor, invoice number, date and total; review these fields before saving.',
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
                                    : _billImagePath == null
                                        ? 'Upload & scan bill / invoice'
                                        : 'Scan bill again'),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Total bill amount (₹) *',
                        prefixText: '₹',
                        helperText:
                            'Enter the amount printed on the bill. Review the OCR value or type it manually.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _billDate ?? _serviceDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _billDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Bill date',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(DateFormat('dd MMM yyyy')
                            .format(_billDate ?? _serviceDate)),
                      ),
                    ),
                    if (_billImagePath != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 16),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                                'Bill image attached; it will be stored with this vehicle and service.',
                                style: TextStyle(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            tooltip: 'Remove bill image',
                            onPressed: () => setState(() {
                              _billImagePath = null;
                              _billScanned = false;
                              _ocrConfidence = null;
                            }),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ],
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
