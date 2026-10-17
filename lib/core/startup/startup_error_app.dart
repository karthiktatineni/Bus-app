import 'package:flutter/material.dart';

class FleetPulseStartupException implements Exception {
  const FleetPulseStartupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FleetPulseStartupErrorApp extends StatelessWidget {
  const FleetPulseStartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final isConfigurationError = error is FleetPulseStartupException;
    final detail = error.toString();

    return MaterialApp(
      title: 'FleetPulse startup error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_off, size: 42, color: Colors.orange),
                    const SizedBox(height: 20),
                    Text(
                      isConfigurationError
                          ? 'App configuration is missing'
                          : 'FleetPulse could not start',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isConfigurationError
                          ? 'This APK was built without its Supabase project settings. '
                              'Set SUPABASE_URL and SUPABASE_ANON_KEY in the local .env file, '
                              'then rebuild with scripts/build_android.ps1.'
                          : 'FleetPulse could not initialize its Supabase or secure sign-in client. '
                              'Check the error details and rebuild after correcting the startup configuration.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
