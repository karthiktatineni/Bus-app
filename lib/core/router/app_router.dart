import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/vehicles/presentation/vehicles_list_screen.dart';
import '../../features/vehicles/presentation/vehicle_detail_screen.dart';
import '../../features/vehicles/presentation/add_edit_vehicle_screen.dart';
import '../../features/services/presentation/service_history_screen.dart';
import '../../features/services/presentation/service_detail_screen.dart';
import '../../features/services/presentation/add_service_screen.dart';
import '../../features/services/presentation/reminders_screen.dart';
import '../../features/bills/presentation/bills_list_screen.dart';
import '../../features/bills/presentation/bill_detail_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/help_support_screen.dart';
import '../../features/chat/presentation/fleet_ai_screen.dart';
import 'route_guards.dart';

enum AppRoute {
  login,
  forgotPassword,
  dashboard,
  vehicles,
  vehicleDetail,
  addVehicle,
  editVehicle,
  services,
  serviceDetail,
  editService,
  addService,
  reminders,
  bills,
  billDetail,
  users,
  settings,
  support,
  fleetAi,
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authControllerProvider);
    return RouteGuards.checkRedirect(
      location: state.uri.path,
      isAuthenticated: authState.isAuthenticated,
      currentUser: authState.user,
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: AppRoute.forgotPassword.name,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/',
            name: AppRoute.dashboard.name,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/vehicles',
            name: AppRoute.vehicles.name,
            builder: (context, state) => const VehiclesListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: AppRoute.addVehicle.name,
                builder: (context, state) => const AddEditVehicleScreen(),
              ),
              GoRoute(
                path: ':id',
                name: AppRoute.vehicleDetail.name,
                builder: (context, state) => VehicleDetailScreen(
                  vehicleId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: AppRoute.editVehicle.name,
                    builder: (context, state) => AddEditVehicleScreen(
                      vehicleId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/services',
            name: AppRoute.services.name,
            builder: (context, state) => const ServiceHistoryScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: AppRoute.addService.name,
                builder: (context, state) => AddServiceScreen(
                  preselectedVehicleId: state.uri.queryParameters['vehicleId'],
                ),
              ),
              GoRoute(
                path: ':id',
                name: AppRoute.serviceDetail.name,
                builder: (context, state) => ServiceDetailScreen(
                  serviceId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: AppRoute.editService.name,
                    builder: (context, state) => AddServiceScreen(
                      serviceId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/bills',
            name: AppRoute.bills.name,
            builder: (context, state) => const BillsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: AppRoute.billDetail.name,
                builder: (context, state) => BillDetailScreen(
                  billId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/reminders',
            name: AppRoute.reminders.name,
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: '/users',
            name: AppRoute.users.name,
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: AppRoute.settings.name,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/support',
            name: AppRoute.support.name,
            builder: (context, state) => const HelpSupportScreen(),
          ),
          GoRoute(
            path: '/fleet-ai',
            name: AppRoute.fleetAi.name,
            builder: (context, state) => const FleetAiScreen(),
          ),
        ],
      ),
    ],
  );
});
