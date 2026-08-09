import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A shared back button widget customized for RTL layout.
/// Displays a chevron pointing right (correct back direction for Farsi/RTL).
class PhysiqoBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;
  final double size;

  const PhysiqoBackButton({
    super.key,
    this.onTap,
    this.color = AppTheme.textPrimary,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Icon(
        Icons.chevron_right,
        color: color,
        size: size,
      ),
    );
  }
}
