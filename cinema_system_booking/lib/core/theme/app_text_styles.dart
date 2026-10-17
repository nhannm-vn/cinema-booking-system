import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle _s({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.ink,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle get displayMega =>
      _s(size: 32, weight: FontWeight.w500, height: 1.1, letterSpacing: -0.64);
  static TextStyle get displayXl =>
      _s(size: 28, weight: FontWeight.w500, height: 1.1, letterSpacing: -0.56);
  static TextStyle get displayLg =>
      _s(size: 24, weight: FontWeight.w500, height: 1.2, letterSpacing: -0.24);
  static TextStyle get displayMd =>
      _s(size: 20, weight: FontWeight.w500, height: 1.4, letterSpacing: 0.15);
  static TextStyle get titleMd =>
      _s(size: 18, weight: FontWeight.w700, height: 1.2);
  static TextStyle get titleSm =>
      _s(size: 16, weight: FontWeight.w500, height: 1.4, letterSpacing: 0.08);
  static TextStyle get bodyMd =>
      _s(size: 14, weight: FontWeight.w400, height: 1.5, color: AppColors.body);
  static TextStyle get bodySm =>
      _s(size: 13, weight: FontWeight.w400, height: 1.5, color: AppColors.body);
  static TextStyle get caption => _s(
      size: 12, weight: FontWeight.w400, height: 1.4, color: AppColors.muted);
  static TextStyle get captionUppercase =>
      _s(size: 11, weight: FontWeight.w600, height: 1.4, letterSpacing: 1.1);
  static TextStyle get button =>
      _s(size: 14, weight: FontWeight.w700, height: 1.0, letterSpacing: 1.4);
  static TextStyle get navLink =>
      _s(size: 13, weight: FontWeight.w600, height: 1.4, letterSpacing: 0.65);
  static TextStyle get numberDisplay =>
      _s(size: 48, weight: FontWeight.w700, height: 1.0, letterSpacing: -0.96);
}
