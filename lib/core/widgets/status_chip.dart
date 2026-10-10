import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ChipStatus { operational, warning, danger, info }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipStatus status;

  const StatusChip({super.key, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (status) {
      case ChipStatus.operational:
        bg = const Color(0xFFE8F5E9);
        fg = AppTheme.success;
        border = const Color(0xFFA3D9A5);
        break;
      case ChipStatus.warning:
        bg = const Color(0xFFFFF4E5);
        fg = AppTheme.warning;
        border = const Color(0xFFFFD599);
        break;
      case ChipStatus.danger:
        bg = const Color(0xFFFEECEB);
        fg = AppTheme.danger;
        border = const Color(0xFFFECDCA);
        break;
      case ChipStatus.info:
        bg = const Color(0xFFE9EDFF);
        fg = AppTheme.info;
        border = const Color(0xFFA0C9FF);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
