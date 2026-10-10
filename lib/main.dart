import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  runApp(
    ProviderScope(
      child: FleetPulseApp(),
    ),
  );
}

class FleetPulseApp extends StatelessWidget {
  FleetPulseApp({Key? key}) : super(key: key);

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FleetPulse Bus Maintenance',
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00355f),
          brightness: Brightness.light,
          background: const Color(0xFFf9f9ff),
        ),
        fontFamily: 'Hanken Grotesk',
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
