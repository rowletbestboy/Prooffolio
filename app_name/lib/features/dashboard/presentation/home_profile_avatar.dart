import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeProfileAvatar extends StatelessWidget {
  const HomeProfileAvatar({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.onTap,
  });

  final String displayName;
  final String? photoUrl;
  final VoidCallback? onTap;

  String get _initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    final initials = parts.take(2).map((part) => part.substring(0, 1));
    return initials.join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final child = url == null || url.isEmpty
        ? _initialsLabel(context)
        : ClipOval(
            child: Image.network(
              url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _initialsLabel(context),
            ),
          );
    return Tooltip(
      message: 'Profile and background',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.indigoContainer,
              shape: BoxShape.circle,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _initialsLabel(BuildContext context) => Text(
    _initials,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: AppColors.deepNavy,
      fontWeight: FontWeight.w700,
    ),
  );
}
