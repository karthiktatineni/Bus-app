import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _chassisController;
  late TextEditingController _engineController;
  late TextEditingController _seatsController;
  late TextEditingController _odometerController;

  String _selectedMake = 'Ashok Leyland';
  String _selectedDepot = 'Bengaluru Central';
  String _selectedFuel = 'Diesel';
  VehicleStatus _selectedStatus = VehicleStatus.active;

  @override
  void initState() {
    super.initState();
    _regController = TextEditingController();
    _modelController = TextEditingController();
    _yearController = TextEditingController(text: '2023');
    _chassisController = TextEditingController();
    _engineController = TextEditingController();
    _seatsController = TextEditingController(text: '42');
    _odometerController = TextEditingController(text: '12500');

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
        _modelController.text = vehicle.model;
        _yearController.text = vehicle.year.toString();
        _chassisController.text = vehicle.chassisNo;
        _engineController.text = vehicle.engineNo;
        _seatsController.text = vehicle.seats.toString();
        _odometerController.text = vehicle.odometerKm.toString();
        _selectedMake = vehicle.make;
        _selectedDepot = vehicle.depot;
        _selectedFuel = vehicle.fuelType;
        _selectedStatus = vehicle.status;
      });
    }
  }

  @override
  void dispose() {
    _regController.dispose();
    _modelController.dispose();
    _yearController.dispose();
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

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final vehicle = Vehicle(
      id: widget.vehicleId ?? 'veh_${DateTime.now().millisecondsSinceEpoch}',
      registrationNo: _regController.text.trim().toUpperCase(),
      make: _selectedMake,
      model: _modelController.text.trim(),
      year: int.tryParse(_yearController.text.trim()) ?? 2023,
      chassisNo: _chassisController.text.trim().toUpperCase(),
      engineNo: _engineController.text.trim().toUpperCase(),
      seats: int.tryParse(_seatsController.text.trim()) ?? 42,
      fuelType: _selectedFuel,
      odometerKm: int.tryParse(_odometerController.text.trim()) ?? 12500,
      depot: _selectedDepot,
      purchaseDate: DateTime(2023, 1, 1),
      status: _selectedStatus,
    );

    final repo = ref.read(vehicleRepositoryProvider);
    if (widget.vehicleId != null) {
      await repo.update(vehicle);
    } else {
      await repo.create(vehicle);
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
    final makes = <String>[
      'Ashok Leyland',
      'Tata Motors',
      'Eicher',
      'Volvo',
      'BharatBenz',
    ];
    final depots = <String>[
      'Bengaluru Central',
      'Hyderabad East Depot',
      'Pune Industrial Bay',
      'Chennai Hub',
    ];
    final fuels = <String>['Diesel', 'CNG', 'Electric (EV)'];
    // Existing fleet records may contain values outside the starter options.
    // Keep them selectable while editing instead of crashing the whole screen.
    if (_selectedMake.isNotEmpty && !makes.contains(_selectedMake)) {
      makes.insert(0, _selectedMake);
    }
    if (_selectedDepot.isNotEmpty && !depots.contains(_selectedDepot)) {
      depots.insert(0, _selectedDepot);
    }
    if (_selectedFuel.isNotEmpty && !fuels.contains(_selectedFuel)) {
      fuels.insert(0, _selectedFuel);
    }

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
                      Row(
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
                          const SizedBox(width: 8),
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
                          hintText: 'TS 09 UB 4521',
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
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedMake,
                              decoration:
                                  const InputDecoration(labelText: 'Make *'),
                              items: makes
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text(m)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedMake = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mfg Year *',
                                hintText: '2023',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                final year = int.tryParse(val.trim());
                                if (year == null ||
                                    year < 2000 ||
                                    year > 2026) {
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
                          hintText: 'Viking 180HP BS6 Wheelbase 5334',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Model variant is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDepot,
                        decoration: const InputDecoration(
                            labelText: 'Assigned Depot *'),
                        items: depots
                            .map((d) =>
                                DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDepot = val);
                        },
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
                      Row(
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
                          const SizedBox(width: 8),
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
                          hintText: 'MB1A3C2D4E5F67890',
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
                          hintText: 'H4E3D2C1B98765',
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
                                hintText: '42',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedFuel,
                              decoration: const InputDecoration(
                                  labelText: 'Fuel System *'),
                              items: fuels
                                  .map((f) => DropdownMenuItem(
                                      value: f, child: Text(f)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedFuel = val);
                                }
                              },
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
                          hintText: '12500',
                          suffixText: 'KM',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Odometer reading is required';
                          }
                          return null;
                        },
                      ),
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
}
