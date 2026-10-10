import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isDestructive;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSecondary = false,
    this.isDestructive = false,
    this.isLoading = false,
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
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        side: border,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isSecondary ? AppTheme.primaryColor : AppTheme.onPrimaryColor,
              ),
            )
          : Text(text),
    );
  }
}
