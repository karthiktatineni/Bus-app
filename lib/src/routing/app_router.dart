import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

enum AppRoute {
  login,
  dashboard,
}

@riverpod
GoRouter goRouter(GoRouterRef ref) {
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
}
