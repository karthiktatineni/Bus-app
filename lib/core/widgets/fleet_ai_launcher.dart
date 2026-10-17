import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FleetAiAppOverlay extends StatelessWidget {
  const FleetAiAppOverlay({
    super.key,
    required this.child,
    required this.currentPath,
  });

  final Widget child;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final isServiceEntryForm = currentPath == '/services/add' ||
        RegExp(r'^/services/[^/]+/edit$').hasMatch(currentPath);
    final showLauncher =
        currentPath != '/fleet-ai' &&
        !isServiceEntryForm &&
        MediaQuery.viewInsetsOf(context).bottom == 0;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (showLauncher)
          Positioned(
            right: 14,
            bottom: 12,
            child: SafeArea(
              child: FloatingActionButton.extended(
                heroTag: 'fleet-ai-global-launcher',
                tooltip: 'Ask AI questions',
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Ask AI questions'),
                onPressed: () => context.push('/fleet-ai'),
              ),
            ),
          ),
      ],
    );
  }
}
