import 'dart:math';
import 'package:bus_app/core/errors/app_exception.dart';

class MockDelay {
  static final Random _random = Random();

  /// Set to false in unit tests to make mock repositories instantaneous.
  static bool enableDelays = true;

  /// Simulates network latency between 300ms and 800ms unless enableDelays is false.
  static Future<void> simulate({
    int minMs = 300,
    int maxMs = 800,
    bool shouldFail = false,
    String? failureMessage,
    bool? overrideDelay,
  }) async {
    final useDelay = overrideDelay ?? enableDelays;
    if (useDelay && maxMs > 0) {
      final delayMs = minMs + _random.nextInt(maxMs - minMs + 1);
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    if (shouldFail) {
      throw SimulationException(
        failureMessage ?? 'Simulated error path triggered for testing.',
      );
    }
  }
}
