import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:bus_app/main.dart';
import 'package:bus_app/core/theme/app_theme.dart';
import 'package:bus_app/core/widgets/app_button.dart';
import 'package:bus_app/core/widgets/status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Theme and core widgets test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                const AppButton(text: 'Test Button'),
                const StatusChip(label: 'Active', status: ChipStatus.operational),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify AppButton exists
    expect(find.text('Test Button'), findsOneWidget);
    
    // Verify StatusChip exists
    expect(find.text('Active'), findsOneWidget);
  });
}
