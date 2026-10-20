import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static final ThemeData light = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.indigo,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.indigoContainer,
          onPrimaryContainer: AppColors.deepNavy,
          secondary: AppColors.teal,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.tealContainer,
          onSecondaryContainer: AppColors.deepNavy,
          tertiary: AppColors.deepNavy,
          onTertiary: AppColors.white,
          error: AppColors.error,
          onError: AppColors.white,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.error,
          surface: AppColors.white,
          onSurface: AppColors.slateBlack,
          onSurfaceVariant: AppColors.slateGray,
          outline: AppColors.slateGray,
          outlineVariant: AppColors.lightSlate,
          surfaceContainerLowest: AppColors.white,
          surfaceContainerLow: AppColors.cloudWhite,
          surfaceContainer: AppColors.cloudWhite,
          surfaceContainerHigh: const Color(0xFFF1F5F9),
          surfaceContainerHighest: AppColors.lightSlate,
          inverseSurface: AppColors.deepNavy,
          onInverseSurface: AppColors.white,
          inversePrimary: const Color(0xFFC7D2FE),
        );

    const textTheme = TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.deepNavy,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        color: AppColors.deepNavy,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
      ),
      headlineSmall: TextStyle(
        color: AppColors.deepNavy,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        color: AppColors.deepNavy,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: AppColors.slateBlack,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        color: AppColors.slateBlack,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        color: AppColors.slateBlack,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.slateGray,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppColors.slateGray,
        fontSize: 12,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        color: AppColors.slateBlack,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      labelMedium: TextStyle(
        color: AppColors.slateGray,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
    );

    const radius = 14.0;
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final outlinedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AppColors.lightSlate),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cloudWhite,
      dividerColor: AppColors.lightSlate,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cloudWhite,
        foregroundColor: AppColors.deepNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.deepNavy,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: outlinedShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.lightSlate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.lightSlate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(roundedShape),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(outlinedShape),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.lightSlate),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.indigoContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.deepNavy : AppColors.slateGray,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightSlate,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
