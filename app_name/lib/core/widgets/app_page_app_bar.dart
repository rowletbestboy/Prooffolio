import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_brand_mark.dart';

class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBrand = true,
  });

  static const double toolbarHeight = 56;

  final String title;
  final List<Widget>? actions;
  final bool showBrand;

  @override
  Size get preferredSize => const Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: AppColors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: 12,
      backgroundColor: AppColors.deepNavy,
      foregroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.controlRadius),
          bottomRight: Radius.circular(AppTheme.controlRadius),
        ),
      ),
      title: showBrand
          ? Row(
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: AppBrandMark(compact: true, inverse: true),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ],
            )
          : Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
      actions: actions,
    );
  }
}
