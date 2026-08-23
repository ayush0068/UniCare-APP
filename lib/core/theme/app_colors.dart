import 'package:flutter/material.dart';

/// UniCare+ color palette — modern healthcare, light theme.
/// Dark theme values can be added alongside these later without
/// touching any screen code, since screens only ever reference
/// AppColors / Theme.of(context), never raw hex values.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0D9488); // teal-600, calm/medical
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color accentBlue = Color(0xFF2563EB); // used for video/consult CTAs

  // Backgrounds
  static const Color background = Color(0xFFF7FAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F5);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Misc
  static const Color border = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A0F172A);

  // Quick-action tile background tints (soft, distinct per action)
  static const Color tintTeal = Color(0xFFCCFBF1);
  static const Color tintBlue = Color(0xFFDBEAFE);
  static const Color tintPurple = Color(0xFFEDE9FE);
  static const Color tintOrange = Color(0xFFFFEDD5);
  static const Color tintPink = Color(0xFFFCE7F3);
  static const Color tintRed = Color(0xFFFEE2E2);
}