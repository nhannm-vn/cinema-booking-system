import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand — Rosso Corsa (dùng tiết kiệm)
  static const primary = Color(0xFFDA291C);
  static const primaryActive = Color(0xFFB01E0A);
  static const primaryHover = Color(0xFF9D2211);

  // Surface
  static const canvas = Color(0xFF181818);
  static const canvasElevated = Color(0xFF303030);
  static const canvasLight = Color(0xFFFFFFFF); // Chỉ dùng cho vé / bảng giá
  static const surfaceSoftLight = Color(0xFFF7F7F7);
  static const surfaceStrongLight = Color(0xFFEBEBEB);

  // Hairline
  static const hairline = Color(0xFF303030);
  static const hairlineOnLight = Color(0xFFD2D2D2);
  static const hairlineSoft = Color(0xFFEBEBEB);

  // Text
  static const ink = Color(0xFFFFFFFF);
  static const body = Color(0xFF969696);
  static const bodyOnLight = Color(0xFF181818);
  static const muted = Color(0xFF666666);
  static const mutedSoft = Color(0xFF8F8F8F);
  static const onPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const info = Color(0xFF4C98B9);
  static const success = Color(0xFF03904A);
  static const warning = Color(0xFFF13A2C);

  // Chỉ dùng cho viền focus của ô nhập
  static const focusRing = Color(0xFFF6E500);

  // Skeleton loading
  static const shimmerHighlight = Color(0xFF3C3C3C);

  // Ghế
  static const seatAvailable = canvasElevated;
  static const seatSelected = primary;
  static const seatHeld = muted;
  static const seatSold = canvas;
}
