import 'package:bus_app/core/startup/startup_error_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('missing build configuration shows recovery instructions',
      (tester) async {
    await tester.pumpWidget(const FleetPulseStartupErrorApp(
      error: FleetPulseStartupException(
        'This build is missing SUPABASE_URL or SUPABASE_ANON_KEY.',
      ),
    ));

    expect(find.text('App configuration is missing'), findsOneWidget);
    expect(find.textContaining('scripts/build_android.ps1'), findsOneWidget);
    expect(find.textContaining('scripts/build_android.ps1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialization errors are presented instead of a blank screen',
      (tester) async {
    await tester.pumpWidget(
      const FleetPulseStartupErrorApp(error: 'secure storage unavailable'),
    );

    expect(find.text('FleetPulse could not start'), findsOneWidget);
    expect(find.text('secure storage unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
