import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/media_service.dart';
import '../providers.dart';

class AddEditVehicleScreen extends ConsumerStatefulWidget {
  final String? vehicleId;

  const AddEditVehicleScreen({
    super.key,
    this.vehicleId,
  });

  @override
  ConsumerState<AddEditVehicleScreen> createState() =>
      _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _isLoading = false;

  late TextEditingController _regController;
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _depotController;
  late TextEditingController _fuelController;
  late TextEditingController _chassisController;
  late TextEditingController _engineController;
  late TextEditingController _seatsController;
  late TextEditingController _odometerController;

  DateTime? _purchaseDate;
  VehicleStatus _selectedStatus = VehicleStatus.active;
  final List<String> _pendingPhotos = [];
  final List<String> _existingPhotos = [];
  final List<VehicleDocument> _pendingDocuments = [];
  final List<VehicleDocument> _existingDocuments = [];

  @override
  void initState() {
    super.initState();
    _regController = TextEditingController();
    _makeController = TextEditingController();
    _modelController = TextEditingController();
    _yearController = TextEditingController();
    _depotController = TextEditingController();
    _fuelController = TextEditingController();
    _chassisController = TextEditingController();
    _engineController = TextEditingController();
    _seatsController = TextEditingController();
    _odometerController = TextEditingController();

    if (widget.vehicleId != null) {
      _loadVehicleData();
    }
  }

  Future<void> _loadVehicleData() async {
    final vehicle =
        await ref.read(vehicleRepositoryProvider).get(widget.vehicleId!);
    if (mounted) {
      setState(() {
        _regController.text = vehicle.registrationNo;
        _makeController.text = vehicle.make;
        _modelController.text = vehicle.model;
        _yearController.text = vehicle.year.toString();
        _chassisController.text = vehicle.chassisNo;
        _engineController.text = vehicle.engineNo;
        _seatsController.text = vehicle.seats.toString();
        _odometerController.text = vehicle.odometerKm.toString();
        _depotController.text = vehicle.depot;
        _fuelController.text = vehicle.fuelType;
        _purchaseDate = vehicle.purchaseDate;
        _selectedStatus = vehicle.status;
        _existingPhotos
          ..clear()
          ..addAll(vehicle.photos);
        _existingDocuments
          ..clear()
          ..addAll(vehicle.documents);
      });
    }
  }

  Future<void> _pickBusPhotos() async {
    try {
      final media = ref.read(mediaServiceProvider);
      final paths = await media.pickMultipleImages();
      final compressed = <String>[];
      for (final path in paths) {
        compressed.add(await media.compressImage(path));
      }
      if (!mounted || compressed.isEmpty) return;
      setState(() {
        _pendingPhotos.addAll(compressed);
        _isDirty = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select bus photos.')),
      );
    }
  }

  Future<void> _addDocumentImage() async {
    try {
      final media = ref.read(mediaServiceProvider);
      final path = await media.pickImageFromCamera() ??
          await media.pickImageFromGallery();
      if (path == null || !mounted) return;
      final compressed = await media.compressImage(path);
      if (!mounted) return;
      final document = await _documentDetailsDialog(compressed);
      if (!mounted || document == null) return;
      setState(() {
        _pendingDocuments.add(document);
        _isDirty = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not attach the document image.')),
      );
    }
  }

  Future<VehicleDocument?> _documentDetailsDialog(String filePath) async {
    var type = DocumentType.insurance;
    var expiry = DateTime.now().add(const Duration(days: 365));
    final numberController = TextEditingController();
    try {
      return await showDialog<VehicleDocument>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Vehicle document details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<DocumentType>(
                    initialValue: type,
                    decoration:
                        const InputDecoration(labelText: 'Document type'),
                    items: DocumentType.values
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberController,
                    decoration:
                        const InputDecoration(labelText: 'Document number'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: expiry,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setDialogState(() => expiry = selected);
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: Text(
                        'Expires ${MaterialLocalizations.of(context).formatMediumDate(expiry)}'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final number = numberController.text.trim();
                  if (number.isEmpty) return;
                  Navigator.pop(
                    dialogContext,
                    VehicleDocument(
                      id: 'pending_${DateTime.now().microsecondsSinceEpoch}',
                      type: type,
                      number: number,
                      expiryDate: expiry,
                      fileUrl: filePath,
                    ),
                  );
                },
                child: const Text('Attach'),
              ),
            ],
          ),
        ),
      );
    } finally {
      numberController.dispose();
    }
  }

  @override
  void dispose() {
    _regController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _depotController.dispose();
    _fuelController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _seatsController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  String? _requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _saveVehicle() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the vehicle purchase date.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final vehicle = Vehicle(
      id: widget.vehicleId ?? 'veh_${DateTime.now().millisecondsSinceEpoch}',
      registrationNo: _regController.text.trim().toUpperCase(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      chassisNo: _chassisController.text.trim().toUpperCase(),
      engineNo: _engineController.text.trim().toUpperCase(),
      seats: int.parse(_seatsController.text.trim()),
      fuelType: _fuelController.text.trim(),
      odometerKm: int.parse(_odometerController.text.trim()),
      depot: _depotController.text.trim(),
      purchaseDate: _purchaseDate!,
      status: _selectedStatus,
      photos: List.unmodifiable(_pendingPhotos),
      documents: List.unmodifiable(_pendingDocuments),
    );

    final repo = ref.read(vehicleRepositoryProvider);
    try {
      if (widget.vehicleId != null) {
        await repo.update(vehicle);
      } else {
        await repo.create(vehicle);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not save vehicle or attachments: $error')),
      );
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.vehicleId != null
              ? 'Vehicle updated successfully'
              : 'Vehicle added to fleet'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicleId != null;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle'),
        ),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_isDirty) setState(() => _isDirty = true);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Basic Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.directions_bus,
                                size: 18, color: AppTheme.primaryColor),
                          ),
                          const Text(
                            '1. Basic Information',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _regController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number *',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Registration number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _makeController,
                              decoration:
                                  const InputDecoration(labelText: 'Make *'),
                              validator: _requiredField,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mfg Year *',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final year = int.tryParse(val.trim());
                                if (year == null ||
                                    year < 1900 ||
                                    year > DateTime.now().year) {
                                  return 'Invalid year';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model Variant *',
                        ),
                        validator: _requiredField,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _depotController,
                        decoration: const InputDecoration(
                            labelText: 'Assigned Depot *'),
                        validator: _requiredField,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Technical & Capacity Specs Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.precision_manufacturing,
                                size: 18, color: AppTheme.primaryColor),
                          ),
                          const Text(
                            '2. Technical & Capacity Specs',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _chassisController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Chassis VIN *',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Chassis VIN is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _engineController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Engine Number *',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Engine number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _seatsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Seating Capacity *',
                              ),
                              validator: (val) {
                                final seats = int.tryParse(val?.trim() ?? '');
                                if (seats == null || seats <= 0) {
                                  return 'Enter a valid seat count';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _fuelController,
                              decoration: const InputDecoration(
                                  labelText: 'Fuel System *'),
                              validator: _requiredField,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _odometerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Odometer (km) *',
                          suffixText: 'KM',
                        ),
                        validator: (val) {
                          final odometer = int.tryParse(val?.trim() ?? '');
                          if (odometer == null || odometer < 0) {
                            return 'Enter a valid odometer reading';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _purchaseDate ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (selected != null) {
                            setState(() {
                              _purchaseDate = selected;
                              _isDirty = true;
                            });
                          }
                        },
                        icon: const Icon(Icons.event_outlined),
                        label: Text(_purchaseDate == null
                            ? 'Set purchase date *'
                            : 'Purchase date: ${MaterialLocalizations.of(context).formatMediumDate(_purchaseDate!)}'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. Bus documents & photos',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _pickBusPhotos,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Add bus photos'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _addDocumentImage,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Scan / add document'),
                          ),
                        ],
                      ),
                      if (_existingPhotos.isNotEmpty ||
                          _pendingPhotos.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Bus photos',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final path in _existingPhotos)
                              _photoThumbnail(path),
                            for (final path in _pendingPhotos)
                              Stack(
                                children: [
                                  _photoThumbnail(path),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton.filledTonal(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Remove selected photo',
                                      onPressed: () => setState(
                                          () => _pendingPhotos.remove(path)),
                                      icon: const Icon(Icons.close, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                      if (_existingDocuments.isNotEmpty ||
                          _pendingDocuments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Vehicle documents',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        for (final document in [
                          ..._existingDocuments,
                          ..._pendingDocuments,
                        ])
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.description_outlined),
                            title: Text(document.type.label),
                            subtitle: Text(
                                '${document.number} • Expires ${MaterialLocalizations.of(context).formatMediumDate(document.expiryDate)}'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final shouldLeave = await _onWillPop();
                        if (shouldLeave && context.mounted) context.pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _saveVehicle,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEdit ? 'Save Changes' : 'Save Vehicle'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoThumbnail(String path) {
    final isLocal = !path.startsWith('https://') && !path.startsWith('http://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 76,
        height: 76,
        child: isLocal
            ? Image.file(File(path), fit: BoxFit.cover)
            : Image.network(path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppTheme.surfaceMuted,
                      child: Icon(Icons.broken_image_outlined),
                    )),
      ),
    );
  }
}
