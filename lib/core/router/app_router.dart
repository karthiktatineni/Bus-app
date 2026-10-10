import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import 'route_guards.dart';

enum AppRoute {
  login,
  forgotPassword,
  dashboard,
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
      GoRoute(
        path: '/',
        name: AppRoute.dashboard.name,
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard (Mock)'),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  return IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign Out',
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).signOut();
                    },
                  );
                },
              ),
            ],
          ),
          body: Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authControllerProvider).user;
              return Center(
                child: Text('Welcome, ${user?.name ?? 'User'} (${user?.role.name.toUpperCase() ?? ''})'),
              );
            },
          ),
        ),
      ),
    ],
  );
});
