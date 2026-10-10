import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isDestructive;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSecondary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppTheme.primaryColor;
    Color fg = AppTheme.onPrimaryColor;
    BorderSide border = BorderSide.none;

    if (isDestructive) {
      bg = AppTheme.danger;
    } else if (isSecondary) {
      bg = AppTheme.surface;
      fg = AppTheme.primaryColor;
      border = const BorderSide(color: AppTheme.primaryColor, width: 1);
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        side: border,
      ),
      child: Text(text),
    );
  }
}
