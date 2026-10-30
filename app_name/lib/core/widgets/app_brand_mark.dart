import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.inverse = false, this.compact = false});

  final bool inverse;
  final bool compact;

  static const _fullLogoAsset = 'assets/prooffolio_logo_clean.png';
  static const _compactLogoAsset = 'assets/prooffolio_mark_clean.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Prooffolio',
      image: true,
      child: Container(
        padding: inverse ? const EdgeInsets.all(8) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: inverse ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
        ),
        child: Image.asset(
          compact ? _compactLogoAsset : _fullLogoAsset,
          width: compact ? 38 : 150,
          height: compact ? 38 : 118,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
