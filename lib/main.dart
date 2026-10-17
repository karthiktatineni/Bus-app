import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/security/secure_auth_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw StateError(
        'Provide SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.');
  }
  final projectKey = Uri.parse(supabaseUrl).host.split('.').first;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureAuthStorage(
        persistSessionKey: 'sb-$projectKey-auth-token',
      ),
    ),
  );

  runApp(const ProviderScope(child: FleetPulseApp()));
}

class FleetPulseApp extends ConsumerWidget {
  const FleetPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FleetPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
    );
  }
}
