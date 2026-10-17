import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers.dart';
import '../../services/providers.dart';
import '../providers.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleRepo = ref.watch(vehicleRepositoryProvider);
    final serviceRepo = ref.watch(serviceRepositoryProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;

    return FutureBuilder<Vehicle?>(
      future: vehicleRepo.get(widget.vehicleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Bus...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final vehicle = snapshot.data;
        if (vehicle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bus Not Found')),
            body: const Center(child: Text('Vehicle not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(vehicle.registrationNo),
            actions: [
              IconButton(
                tooltip: 'Refresh vehicle details',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(vehicleRepositoryProvider);
                  ref.invalidate(serviceRepositoryProvider);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Vehicle',
                onPressed: () => context.go('/vehicles/${vehicle.id}/edit'),
              ),
              if (isAdmin)
                IconButton(
                  tooltip: 'Archive bus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      _archiveVehicle(context, vehicleRepo, vehicle),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Service history'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Documents'),
                Tab(text: 'Photos'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(vehicle, serviceRepo),
              _buildServiceHistoryTab(vehicle, serviceRepo),
              _buildUpcomingTab(vehicle, serviceRepo),
              _buildDocumentsTab(vehicle, vehicleRepo),
              _buildPhotosTab(vehicle, vehicleRepo),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(Vehicle vehicle, ServiceRepository serviceRepo) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Vehicle Header Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: const Icon(Icons.directions_bus,
                      color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vehicle.registrationNo,
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(vehicle.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.make} ${vehicle.model} • ${vehicle.year}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('View upcoming maintenance'),
          onPressed: () => _tabController.animateTo(2),
        ),
        const SizedBox(height: 16),

        // Technical Specs Grid
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vehicle Summary',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _specItem('Odometer',
                        '${NumberFormat('#,###').format(vehicle.odometerKm)} km'),
                    _specItem('Assigned Depot', vehicle.depot),
                    _specItem('Fuel Type', vehicle.fuelType.toUpperCase()),
                    _specItem('Seats', '${vehicle.seats} Seats'),
                    _specItem('Chassis VIN', vehicle.chassisNo),
                    _specItem('Engine No', vehicle.engineNo),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Documents attached to this bus
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Documents',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('${vehicle.documents.length} on file',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                if (vehicle.documents.isEmpty)
                  const Text('No documents added',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary))
                else
                  ...vehicle.documents.indexed.expand((entry) => [
                        if (entry.$1 > 0) const Divider(height: 1),
                        _docRow(
                          entry.$2.type.label,
                          entry.$2.isExpired
                              ? 'Expired'
                              : 'Expires ${DateFormat('dd MMM yyyy').format(entry.$2.expiryDate)}',
                          entry.$2.isExpired
                              ? AppTheme.danger
                              : AppTheme.success,
                        ),
                      ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _specItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _docRow(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          Text(status,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildServiceHistoryTab(
      Vehicle vehicle, ServiceRepository serviceRepo) {
    return FutureBuilder<List<ServiceRecord>>(
      future: serviceRepo.listAll(vehicleId: vehicle.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await context.push(
                      '/services/add?vehicleId=${Uri.encodeComponent(vehicle.id)}');
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add service record'),
              ),
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              const EmptyState(
                  message:
                      'No service records yet. Add the first service, parts, bill and photos above.',
                  icon: Icons.build_outlined)
            else
              ...records.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.go('/services/${r.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.type.label,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₹${NumberFormat('#,###').format(r.total)}',
                                  style: const TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(r.date)} • ${r.workshop} (${r.mechanic})',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            if (r.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r.notes,
                                  style: const TextStyle(fontSize: 12)),
                            ],
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
    );
  }

  Widget _buildUpcomingTab(Vehicle vehicle, ServiceRepository serviceRepo) {
    return FutureBuilder<List<MaintenanceTask>>(
      future: serviceRepo.upcomingTasks(withinDays: 365),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allTasks = snapshot.data ?? [];
        final tasks = allTasks.where((t) => t.vehicleId == vehicle.id).toList();
        if (tasks.isEmpty) {
          return const EmptyState(
              message: 'No upcoming tasks scheduled', icon: Icons.schedule);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final t = tasks[index];
            final isOverdue = t.isOverdue;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        isOverdue
                            ? Icons.warning_amber_rounded
                            : Icons.schedule,
                        color:
                            isOverdue ? AppTheme.danger : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Due ${t.dueDate != null ? DateFormat('dd MMM yyyy').format(t.dueDate!) : 'TBD'} • at ${t.dueKm != null ? NumberFormat('#,###').format(t.dueKm!) : '--'} km',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? AppTheme.danger.withValues(alpha: 0.12)
                              : AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOverdue ? 'Overdue' : 'Scheduled',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? AppTheme.danger
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentsTab(Vehicle vehicle, VehicleRepository vehicleRepo) {
    final docs = vehicle.documents;
    if (docs.isEmpty) {
      return const EmptyState(
          message: 'No documents attached', icon: Icons.description_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final isExpired = doc.isExpired;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  InkWell(
                    onTap: doc.fileUrl == null
                        ? null
                        : () => _showPinchZoomPhoto(
                            context, doc.fileUrl!, doc.type.label),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: doc.fileUrl == null
                          ? const Icon(Icons.description,
                              color: AppTheme.primaryColor, size: 20)
                          : _vehiclePhotoImage(doc.fileUrl!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.type.label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No: ${doc.number} • Expires: ${DateFormat('dd MMM yyyy').format(doc.expiryDate)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? AppTheme.danger.withValues(alpha: 0.12)
                          : AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isExpired ? 'Expired' : 'Valid',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? AppTheme.danger : AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotosTab(Vehicle vehicle, VehicleRepository vehicleRepo) {
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    final photos = vehicle.photos;
    if (photos.isEmpty) {
      return const EmptyState(
          message: 'No vehicle photos available',
          icon: Icons.photo_library_outlined);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photoUrl = photos[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              _showPinchZoomPhoto(context, photoUrl, 'Photo ${index + 1}'),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _vehiclePhotoImage(photoUrl),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Text(
                      'Bus ${vehicle.registrationNo} - Photo ${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isAdmin)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                            width: 40, height: 40),
                        tooltip: 'Delete vehicle photo',
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 20),
                        onPressed: () => _deleteVehiclePhoto(
                            context, vehicleRepo, vehicle, photoUrl),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _vehiclePhotoImage(String photoUrl) {
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: AppTheme.surfaceMuted,
          child: Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }
    return Image.asset(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: AppTheme.surfaceMuted,
        child: Center(child: Icon(Icons.directions_bus)),
      ),
    );
  }

  Future<void> _archiveVehicle(BuildContext context,
      VehicleRepository vehicleRepo, Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive this bus?'),
        content: Text(
          '${vehicle.registrationNo} will be removed from the active fleet. Its service and billing history will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive bus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await vehicleRepo.delete(vehicle.id);
      if (!context.mounted) return;
      ref.invalidate(vehicleListStreamProvider);
      context.go('/vehicles');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus archived. Fleet history was kept.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not archive this bus.')),
      );
    }
  }

  Future<void> _deleteVehiclePhoto(BuildContext context,
      VehicleRepository vehicleRepo, Vehicle vehicle, String photoUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete bus photo?'),
        content: const Text('This photo will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete photo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await vehicleRepo.deletePhoto(vehicle.id, photoUrl);
      if (mounted) setState(() {});
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this bus photo.')),
      );
    }
  }

  void _showPinchZoomPhoto(
      BuildContext context, String photoUrl, String caption) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: _vehiclePhotoImage(photoUrl),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(caption,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Pinch to zoom',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: text),
      ),
    );
  }
}
