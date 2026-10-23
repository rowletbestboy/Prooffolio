import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.inverse = false, this.compact = false});

  final bool inverse;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = inverse ? AppColors.deepNavy : AppColors.white;
    final background = inverse ? AppColors.white : AppColors.indigo;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 44,
          height: compact ? 38 : 44,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.fact_check_outlined,
            color: foreground,
            size: compact ? 22 : 25,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 11),
          Text(
            'Prooffolio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: inverse ? AppColors.white : AppColors.deepNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
