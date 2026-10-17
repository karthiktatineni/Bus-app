import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class VehiclesListScreen extends ConsumerStatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  ConsumerState<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends ConsumerState<VehiclesListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _sortMode = 'Reg'; // 'Reg' or 'Odometer'

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.user?.role == UserRole.admin;
    final vehicleRepo = ref.watch(vehicleRepositoryProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Vehicles List'),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon:
                    const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                tooltip: 'Add Vehicle',
                onPressed: () => context.go('/vehicles/add'),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: vehicleRepo.list(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeleton();
          }

          final allVehicles = snapshot.data ?? [];
          var vehicles = List<Vehicle>.from(allVehicles);

          // Apply search
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            vehicles = vehicles
                .where((v) =>
                    v.registrationNo.toLowerCase().contains(query) ||
                    v.make.toLowerCase().contains(query) ||
                    v.model.toLowerCase().contains(query) ||
                    v.chassisNo.toLowerCase().contains(query))
                .toList();
          }

          // Apply filter
          if (_selectedFilter == 'Active') {
            vehicles = vehicles
                .where((v) => v.status == VehicleStatus.active)
                .toList();
          } else if (_selectedFilter == 'In workshop') {
            vehicles = vehicles
                .where((v) => v.status == VehicleStatus.inWorkshop)
                .toList();
          } else if (_selectedFilter == 'Overdue') {
            vehicles = vehicles
                .where((v) => v.status == VehicleStatus.overdue)
                .toList();
          } else if (_selectedFilter == 'Due soon') {
            vehicles = vehicles
                .where((v) => v.status == VehicleStatus.dueSoon)
                .toList();
          }

          // Apply sort
          if (_sortMode == 'Reg') {
            vehicles
                .sort((a, b) => a.registrationNo.compareTo(b.registrationNo));
          } else if (_sortMode == 'Odometer') {
            vehicles.sort((a, b) => b.odometerKm.compareTo(a.odometerKm));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top Utility & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Vehicles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${allVehicles.length})',
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Sort button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.swap_vert,
                            size: 16, color: AppTheme.primaryColor),
                        label: Text(
                          'Sort: $_sortMode',
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _sortMode = _sortMode == 'Reg' ? 'Odometer' : 'Reg';
                          });
                        },
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => context.go('/vehicles/add'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search registration, chassis, make...',
                  hintStyle: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 10),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All (${allVehicles.length})',
                    'Due soon (2)',
                    'Overdue (1)',
                    'In workshop (1)',
                    'Active (6)',
                  ].map((filter) {
                    final name =
                        filter.replaceFirst(RegExp(r'\s*\(\d+\)$'), '');
                    final isSelected = _selectedFilter == name ||
                        (_selectedFilter == 'All' && name == 'All');
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        showCheckmark: false,
                        onSelected: (val) =>
                            setState(() => _selectedFilter = name),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // List of cards
              if (vehicles.isEmpty)
                const EmptyState(
                  message: 'No vehicles match your search or filter',
                  icon: Icons.directions_bus_outlined,
                )
              else
                ...vehicles.map((v) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go('/vehicles/${v.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.directions_bus,
                                            color: AppTheme.primaryColor,
                                            size: 22),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.registrationNo,
                                            style: const TextStyle(
                                              fontFamily: 'JetBrainsMono',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '${v.make} ${v.model} (${v.year})',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  _buildStatusBadge(v.status),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ODOMETER',
                                          style: TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: 9,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${NumberFormat('#,###').format(v.odometerKm)} km',
                                          style: const TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'DEPOT',
                                          style: TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: 9,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          v.depot,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.history,
                                          size: 14,
                                          color: AppTheme.textSecondary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Last: 14 Feb 2024',
                                        style: TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month,
                                          size: 14,
                                          color:
                                              v.status == VehicleStatus.overdue
                                                  ? AppTheme.danger
                                                  : AppTheme.primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Next: 10 May 2024',
                                        style: TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              v.status == VehicleStatus.overdue
                                                  ? AppTheme.danger
                                                  : AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 36, width: double.infinity),
        SizedBox(height: 12),
        SkeletonBox(height: 40, width: double.infinity),
        SizedBox(height: 16),
        SkeletonBox(height: 120, width: double.infinity),
        SizedBox(height: 12),
        SkeletonBox(height: 120, width: double.infinity),
        SizedBox(height: 12),
        SkeletonBox(height: 120, width: double.infinity),
      ],
    );
  }

  Widget _buildStatusBadge(VehicleStatus status) {
    Color bg;
    Color text;
    final label = status.label.toUpperCase();

    switch (status) {
      case VehicleStatus.active:
        bg = AppTheme.success.withValues(alpha: 0.12);
        text = AppTheme.success;
        break;
      case VehicleStatus.inWorkshop:
        bg = AppTheme.primaryColor.withValues(alpha: 0.12);
        text = AppTheme.primaryColor;
        break;
      case VehicleStatus.overdue:
        bg = AppTheme.danger.withValues(alpha: 0.12);
        text = AppTheme.danger;
        break;
      case VehicleStatus.dueSoon:
        bg = AppTheme.warning.withValues(alpha: 0.12);
        text = AppTheme.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}
