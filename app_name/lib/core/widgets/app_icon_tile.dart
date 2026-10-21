import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.color = AppColors.indigo,
    this.backgroundColor = AppColors.indigoContainer,
    this.size = 48,
    this.iconSize = 23,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(icon, color: color, size: iconSize),
  );
}
