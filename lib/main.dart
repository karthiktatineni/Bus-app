import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/routing/app_router.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: FleetPulseApp()));
}

class FleetPulseApp extends ConsumerWidget {
  const FleetPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'FleetPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // We will support Dark mode via tokens later
      routerConfig: goRouter,
    );
  }
}
