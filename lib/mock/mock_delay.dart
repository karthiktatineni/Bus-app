import 'dart:math';
import '../core/errors/app_exception.dart';

class MockDelay {
  static final Random _random = Random();

  /// Simulates network latency between 300ms and 800ms
  static Future<void> simulate({
    int minMs = 300,
    int maxMs = 800,
    bool shouldFail = false,
    String? failureMessage,
  }) async {
    final delayMs = minMs + _random.nextInt(maxMs - minMs + 1);
    await Future.delayed(Duration(milliseconds: delayMs));

    if (shouldFail) {
      throw SimulationException(
        failureMessage ?? 'Simulated error path triggered for testing.',
      );
    }
  }
}
