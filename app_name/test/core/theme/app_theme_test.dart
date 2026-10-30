import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme maps shared semantic tokens to app surfaces', () {
    final theme = AppTheme.light;

    expect(AppColors.deepNavy, const Color(0xFF102858));
    expect(AppColors.indigo, const Color(0xFF3E46EF));
    expect(AppColors.teal, const Color(0xFF087C82));
    expect(AppColors.cloudWhite, const Color(0xFFF7F9FF));
    expect(theme.scaffoldBackgroundColor, AppColors.cloudWhite);
    expect(theme.colorScheme.primary, AppColors.indigo);
    expect(theme.colorScheme.surface, AppColors.white);
    expect(theme.useMaterial3, isTrue);
  });

  test('navigation surfaces use shared surface and selection tokens', () {
    final theme = AppTheme.light;

    expect(theme.navigationBarTheme.backgroundColor, AppColors.white);
    expect(theme.navigationBarTheme.indicatorColor, AppColors.indigoContainer);
    expect(theme.navigationRailTheme.backgroundColor, AppColors.white);
    expect(theme.navigationRailTheme.indicatorColor, AppColors.indigoContainer);
  });

  test('cards have subtle elevation above the cool app canvas', () {
    final theme = AppTheme.light;

    expect(theme.cardTheme.elevation, greaterThan(0));
    expect(theme.cardTheme.shadowColor, isNot(Colors.transparent));
  });
}
