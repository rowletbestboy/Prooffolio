import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    icon: const Icon(Icons.keyboard_arrow_down_rounded),
    iconSize: 22,
    style: Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: AppColors.slateBlack),
    dropdownColor: AppColors.white,
    elevation: 4,
    menuMaxHeight: 360,
    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
    decoration: InputDecoration(labelText: label),
    items: items,
    onChanged: onChanged,
  );
}
