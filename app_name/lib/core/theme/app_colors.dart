import 'package:flutter/material.dart';

/// Prooffolio's semantic brand palette.
///
/// Keep color choices centralized here so screens use named roles instead of
/// repeating raw hex values.
abstract final class AppColors {
  static const Color deepNavy = Color(0xFF14213D);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color teal = Color(0xFF0F766E);
  static const Color cloudWhite = Color(0xFFF8FAFC);
  static const Color slateBlack = Color(0xFF0F172A);
  static const Color slateGray = Color(0xFF64748B);
  static const Color lightSlate = Color(0xFFE2E8F0);
  static const Color white = Color(0xFFFFFFFF);

  static const Color indigoContainer = Color(0xFFE0E7FF);
  static const Color tealContainer = Color(0xFFCCFBF1);
  static const Color error = Color(0xFFB42318);
  static const Color errorContainer = Color(0xFFFEE4E2);
}
