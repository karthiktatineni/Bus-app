import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/notifications_sheet.dart';
import '../../../core/widgets/skeleton_box.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/providers.dart';
import '../../vehicles/providers.dart';
import '../../services/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final Set<String> _completedTaskIds = {};
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;

    final vehicleRepo = ref.watch(vehicleRepositoryProvider);
    final serviceRepo = ref.watch(serviceRepositoryProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.appName.toUpperCase()} DEPOT',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'Fleet Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () => NotificationsSheet.show(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          if (mounted) setState(() => _isRefreshing = false);
        },
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            vehicleRepo.list(),
            serviceRepo.upcomingTasks(withinDays: 30),
            serviceRepo.listAll(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isRefreshing) {
              return _buildLoadingSkeleton();
            }

            if (snapshot.hasError) {
              return ErrorState(
                message: 'Failed to load depot data',
                onRetry: () => setState(() {}),
              );
            }

            final vehicles = (snapshot.data?[0] as List<Vehicle>?) ?? [];
            final tasks = (snapshot.data?[1] as List<MaintenanceTask>?) ?? [];
            final serviceRecords =
                (snapshot.data?[2] as List<ServiceRecord>?) ?? [];

            // Metrics calculation
            final inWorkshopBuses = vehicles
                .where((v) => v.status == VehicleStatus.inWorkshop)
                .length;
            final overdueTasks = tasks.where((t) => t.isOverdue).length;
            final due14DaysTasks = tasks.where((t) {
              if (t.isDone || t.dueDate == null) return false;
              final diff = t.dueDate!.difference(DateTime.now()).inDays;
              return diff >= 0 && diff <= 14;
            }).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Greeting & Live Status Banner
                _buildGreetingSection(user?.name ?? 'Fleet manager'),
                const SizedBox(height: 16),

                // Summary Metric Counters
                _buildMetricsSection(
                  overdueCount: overdueTasks,
                  dueSoonCount: due14DaysTasks,
                  inWorkshopCount: inWorkshopBuses,
                ),
                const SizedBox(height: 16),

                // Visual Fleet Context Strip
                _buildContextStrip(),
                const SizedBox(height: 20),

                // To-Do Section with Undo
                _buildTodoSection(tasks),
                const SizedBox(height: 20),

                // Horizontal Next 2 Weeks Flashcards
                _buildFlashcardsSection(vehicles, tasks, serviceRecords),
                const SizedBox(height: 24),

                // All Vehicles Section with Search & Filter
                _buildVehiclesSection(vehicles, isAdmin),
                const SizedBox(height: 20),

                // End-of-shift handover action card
                _buildHandoverCard(),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 60, width: double.infinity),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
            SizedBox(width: 8),
            Expanded(child: SkeletonBox(height: 80, width: double.infinity)),
          ],
        ),
        SizedBox(height: 16),
        SkeletonBox(height: 70, width: double.infinity),
        SizedBox(height: 20),
        SkeletonBox(height: 140, width: double.infinity),
        SizedBox(height: 20),
        SkeletonBox(height: 180, width: double.infinity),
      ],
    );
  }

  Widget _buildGreetingSection(String userName) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final dateStr = DateFormat('dd MMM yyyy').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'DEPOT BAY 04 • BENGALURU CENTRAL',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dateStr,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $userName',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Shift Lead Engineer • 10 vehicles monitored',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.sync, color: AppTheme.primaryColor),
              tooltip: 'Sync depot',
              onPressed: () {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Depot synced successfully'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsSection({
    required int overdueCount,
    required int dueSoonCount,
    required int inWorkshopCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'OVERDUE',
            count: '$overdueCount',
            subtitle: 'Immediate action',
            icon: Icons.warning_amber_rounded,
            backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
            borderColor: AppTheme.danger.withValues(alpha: 0.25),
            textColor: AppTheme.danger,
            onTap: () => context.go('/reminders'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'DUE 14D',
            count: '$dueSoonCount',
            subtitle: 'Due in 14 days',
            icon: Icons.schedule,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderColor: AppTheme.border,
            textColor: Theme.of(context).textTheme.bodyLarge?.color ??
                AppTheme.textPrimary,
            onTap: () => context.go('/reminders'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'IN WORKSHOP',
            count: '$inWorkshopCount',
            subtitle: 'Currently in workshop',
            icon: Icons.home_repair_service_outlined,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderColor: AppTheme.primaryColor.withValues(alpha: 0.25),
            textColor: AppTheme.primaryColor,
            onTap: () => context.go('/services'),
          ),
        ),
      ],
    );
  }

  Widget _buildContextStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_bus,
                color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BENGALURU - PUNE',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Depot Fleet A',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Morning Pre-Trip Audit Live',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '9 of 10 vehicle checks completed for departures',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoSection(List<MaintenanceTask> tasks) {
    final displayTasks = tasks.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'To do',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${displayTasks.length}',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go('/reminders'),
              child: const Row(
                children: [
                  Text('View all'),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Card(
          child: Column(
            children: displayTasks.map((task) {
              final isChecked = _completedTaskIds.contains(task.id);
              final isOverdue = task.isOverdue;

              return Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: isChecked,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) async {
                        if (val == null) return;
                        try {
                          await ref
                              .read(serviceRepositoryProvider)
                              .setTaskDone(task.id, val);
                        } catch (error) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Could not update task: $error')),
                            );
                          }
                          return;
                        }
                        if (!mounted) return;
                        setState(() {
                          if (val) {
                            _completedTaskIds.add(task.id);
                          } else {
                            _completedTaskIds.remove(task.id);
                          }
                        });

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val == true
                                  ? 'Marked "${task.title}" as complete'
                                  : 'Reopened "${task.title}"',
                            ),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () async {
                                await ref
                                    .read(serviceRepositoryProvider)
                                    .setTaskDone(task.id, val != true);
                                if (!mounted) return;
                                setState(() {
                                  if (val == true) {
                                    _completedTaskIds.remove(task.id);
                                  } else {
                                    _completedTaskIds.add(task.id);
                                  }
                                });
                              },
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked
                            ? AppTheme.textSecondary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        const Text(
                          'TS 09 UB 4521',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•',
                            style: TextStyle(color: AppTheme.border)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Bay 1 • Due ${task.dueDate != null ? DateFormat('dd MMM').format(task.dueDate!) : 'Scheduled'}',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 76,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? AppTheme.danger.withValues(alpha: 0.12)
                                : AppTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOverdue ? 'Overdue' : 'Due soon',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOverdue
                                  ? AppTheme.danger
                                  : AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (task != displayTasks.last) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcardsSection(List<Vehicle> vehicles,
      List<MaintenanceTask> tasks, List<ServiceRecord> serviceRecords) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Next 2 weeks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.calendar_month_outlined,
                    size: 16, color: AppTheme.textSecondary),
              ],
            ),
            Text(
              'Scroll to view',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: vehicles.take(3).length,
            itemBuilder: (context, index) {
              final v = vehicles[index];
              final vehicleTasks =
                  tasks.where((t) => t.vehicleId == v.id).toList();
              final isOverdue = vehicleTasks.any((t) => t.isOverdue);
              final isDueSoon = vehicleTasks.any((t) =>
                  !t.isOverdue &&
                  t.dueDate != null &&
                  t.dueDate!.difference(DateTime.now()).inDays <= 14);
              final lastService = serviceRecords
                  .where((record) => record.vehicleId == v.id)
                  .fold<ServiceRecord?>(
                      null,
                      (latest, record) =>
                          latest == null || record.date.isAfter(latest.date)
                              ? record
                              : latest);

              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              v.registrationNo,
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
                                isOverdue
                                    ? 'OVERDUE'
                                    : isDueSoon
                                        ? 'DUE SOON'
                                        : 'ON TRACK',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOverdue
                                      ? AppTheme.danger
                                      : isDueSoon
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${v.make} ${v.model} • ${v.year}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'LAST SERVICE',
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 9,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    lastService == null
                                        ? '—'
                                        : '₹${NumberFormat('#,###').format(lastService.total)}',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                            vehicleTasks.isEmpty
                                ? 'No open maintenance tasks'
                                : vehicleTasks
                                    .take(2)
                                    .map((task) => task.title)
                                    .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10)),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => context.go('/vehicles/${v.id}'),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('View bus',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesSection(List<Vehicle> vehicles, bool isAdmin) {
    var filtered = vehicles;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((v) =>
              v.registrationNo
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              v.make.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              v.model.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedFilter == 'Active') {
      filtered =
          filtered.where((v) => v.status == VehicleStatus.active).toList();
    } else if (_selectedFilter == 'In workshop') {
      filtered =
          filtered.where((v) => v.status == VehicleStatus.inWorkshop).toList();
    } else if (_selectedFilter == 'Overdue') {
      filtered =
          filtered.where((v) => v.status == VehicleStatus.overdue).toList();
    } else if (_selectedFilter == 'Due soon') {
      filtered =
          filtered.where((v) => v.status == VehicleStatus.dueSoon).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'All vehicles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${vehicles.length} buses)',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (isAdmin)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add vehicle',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/vehicles/add'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Search text field
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search registration, chassis, make...',
            hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            prefixIcon: Icon(Icons.search, size: 20),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 10),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'All (${vehicles.length})',
              'Due soon (2)',
              'Overdue (1)',
              'In workshop (1)',
              'Active (6)'
            ].map((filter) {
              final name = filter.replaceFirst(RegExp(r'\s*\(\d+\)$'), '');
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  showCheckmark: false,
                  onSelected: (val) {
                    setState(() => _selectedFilter = name);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Vehicle items list
        Column(
          children: filtered.map((v) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.registrationNo,
                                  style: const TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${v.make} ${v.model} • ${v.year}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            _buildStatusBadge(v.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Last: 14 Feb 2024',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              'Next: 10 May 2024',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: v.status == VehicleStatus.overdue
                                    ? AppTheme.danger
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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

  Widget _buildHandoverCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_turned_in_outlined,
                color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End-of-Shift Handover',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Log bay notes for Night Shift B',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
              elevation: 0,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Handover logged for Night Shift B'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Start',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Icon(icon, size: 14, color: textColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
