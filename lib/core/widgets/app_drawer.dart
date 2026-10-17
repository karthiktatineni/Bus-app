import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';
import '../../features/auth/providers.dart';
import '../../features/vehicles/providers.dart';
import '../../features/services/providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;
    final currentRoute = GoRouterState.of(context).uri.path;

    final vehicleRepo = ref.watch(vehicleRepositoryProvider);
    final serviceRepo = ref.watch(serviceRepositoryProvider);

    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Header Section (Matching 03_drawer.html)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Initials Avatar with online dot
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              _getInitials(user?.name ?? 'User'),
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).cardColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Live Depot indicator pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sensors,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Fleet workspace',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // User name and verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user?.name ?? 'Karthik Tatineni',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.verified,
                          size: 16, color: AppTheme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Role Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppTheme.primaryColor.withValues(alpha: 0.12)
                          : AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAdmin ? 'ADMINISTRATOR' : 'SHIFT LEAD ENGINEER',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            isAdmin ? AppTheme.primaryColor : AppTheme.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Company fleet',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Shift Metrics Strip
            FutureBuilder<List<Vehicle>>(
              future: vehicleRepo.list(),
              builder: (context, snapshot) {
                final total = snapshot.data?.length ?? 10;
                final active = snapshot.data
                        ?.where((v) => v.status == VehicleStatus.active)
                        .length ??
                    7;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ASSIGNED UNITS',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$active / $total Active',
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'SHIFT REMAINING',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              '04h 30m',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 1),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.grid_view,
                    title: 'Dashboard',
                    isSelected: currentRoute == '/',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/') context.go('/');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.directions_bus,
                    title: 'Vehicles',
                    isSelected: currentRoute.startsWith('/vehicles') &&
                        !currentRoute.contains('/add'),
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/vehicles') context.go('/vehicles');
                    },
                  ),
                  if (isAdmin)
                    _DrawerItem(
                      icon: Icons.add_circle_outline,
                      title: 'Add vehicle',
                      isSelected: currentRoute == '/vehicles/add',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/vehicles/add');
                      },
                    ),
                  _DrawerItem(
                    icon: Icons.build_circle_outlined,
                    title: 'Service history',
                    isSelected: currentRoute.startsWith('/services'),
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/services') context.go('/services');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long,
                    title: 'Bills',
                    isSelected: currentRoute.startsWith('/bills'),
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/bills') context.go('/bills');
                    },
                  ),
                  FutureBuilder<List<MaintenanceTask>>(
                    future: serviceRepo.upcomingTasks(withinDays: 30),
                    builder: (context, snapshot) {
                      final overdueCount =
                          snapshot.data?.where((t) => t.isOverdue).length ?? 0;
                      return _DrawerItem(
                        icon: Icons.notifications_active_outlined,
                        title: 'Reminders',
                        isSelected: currentRoute.startsWith('/reminders'),
                        badgeCount: overdueCount > 0 ? overdueCount : null,
                        badgeColor: AppTheme.danger,
                        onTap: () {
                          Navigator.pop(context);
                          if (currentRoute != '/reminders') {
                            context.go('/reminders');
                          }
                        },
                      );
                    },
                  ),
                  if (isAdmin)
                    _DrawerItem(
                      icon: Icons.group_outlined,
                      title: 'Users',
                      isSelected: currentRoute.startsWith('/users'),
                      badgeText: 'ADMIN',
                      badgeColor: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.pop(context);
                        if (currentRoute != '/users') context.go('/users');
                      },
                    ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isSelected: currentRoute.startsWith('/settings'),
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/settings') context.go('/settings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help and support',
                    isSelected: currentRoute == '/support',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/support') context.go('/support');
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Log out item
                  ListTile(
                    leading: const Icon(Icons.logout,
                        color: AppTheme.danger, size: 20),
                    title: const Text(
                      'Log out',
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        size: 18, color: AppTheme.danger),
                    dense: true,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authControllerProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
            ),

            // Bottom Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${AppStrings.appName} v0.1.0',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Fleet maintenance workspace',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badgeText;
  final int? badgeCount;
  final Color? badgeColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.badgeText,
    this.badgeCount,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    const primary = AppTheme.primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color:
            isSelected ? primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            size: 20,
            color: isSelected ? primary : AppTheme.textSecondary,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          trailing: badgeCount != null
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppTheme.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : badgeText != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? AppTheme.textSecondary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeColor ?? AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : (isSelected
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
