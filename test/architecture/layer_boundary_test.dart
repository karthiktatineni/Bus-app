import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture Layer Boundary Tests', () {
    test('Presentation layer must never import from data layer', () {
      final featuresDir = Directory('lib/features');
      if (!featuresDir.existsSync()) return;

      final violations = <String>[];

      for (final entity in featuresDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final normalizedPath = entity.path.replaceAll('\\', '/');

          // Check if file is inside a presentation folder
          if (normalizedPath.contains('/presentation/')) {
            final lines = entity.readAsLinesSync();
            for (int i = 0; i < lines.length; i++) {
              final line = lines[i];
              if (line.trim().startsWith('import ') &&
                  (line.contains('/data/') || line.contains('mock_'))) {
                violations.add(
                  'Violation in $normalizedPath:${i + 1} -> "$line" (Presentation cannot import from Data)',
                );
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Architectural boundary violated:\n${violations.join('\n')}',
      );
    });

    test('All feature providers are centralized in providers.dart', () {
      final requiredProviders = [
        'lib/features/auth/providers.dart',
        'lib/features/vehicles/providers.dart',
        'lib/features/services/providers.dart',
        'lib/features/bills/providers.dart',
        'lib/features/users/providers.dart',
        'lib/features/settings/providers.dart',
        'lib/features/notifications/providers.dart',
      ];

      for (final path in requiredProviders) {
        expect(File(path).existsSync(), isTrue, reason: 'Missing $path');
      }
    });
  });
}
