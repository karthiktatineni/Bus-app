import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/security/secure_auth_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/startup/startup_error_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  try {
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw const FleetPulseStartupException(
        'This build is missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Build the Android app with scripts/build_android.ps1.',
      );
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FleetPulseStartupException(
        'SUPABASE_URL is invalid. Set the HTTPS project URL in .env and '
        'rebuild with scripts/build_android.ps1.',
      );
    }
    final projectKey = uri.host.split('.').first;
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureAuthStorage(
          persistSessionKey: 'sb-$projectKey-auth-token',
        ),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('FleetPulse startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(FleetPulseStartupErrorApp(error: error));
    return;
  }

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
