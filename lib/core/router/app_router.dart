import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

enum AppRoute {
  login,
  dashboard,
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login Screen (Mock)')),
        ),
      ),
      GoRoute(
        path: '/',
        name: AppRoute.dashboard.name,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Dashboard (Mock)')),
        ),
      ),
    ],
  );
});
