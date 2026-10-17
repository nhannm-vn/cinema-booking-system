import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: BorderSide(color: color, width: 1),
      );

  static const _buttonShape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.none));
  static const _buttonMinSize = WidgetStatePropertyAll(Size(0, 48));
  static const _buttonPadding = WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14));
  static const _noOverlay = WidgetStatePropertyAll(Colors.transparent);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.canvasElevated,
        onSecondary: AppColors.ink,
        surface: AppColors.canvas,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.canvasElevated,
        error: AppColors.warning,
        onError: AppColors.ink,
        outline: AppColors.hairline,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayMega,
        displayMedium: AppTextStyles.displayXl,
        displaySmall: AppTextStyles.displayLg,
        headlineMedium: AppTextStyles.displayMd,
        titleLarge: AppTextStyles.titleMd,
        titleMedium: AppTextStyles.titleSm,
        bodyLarge: AppTextStyles.bodyMd,
        bodyMedium: AppTextStyles.bodyMd,
        bodySmall: AppTextStyles.bodySm,
        labelLarge: AppTextStyles.button,
        labelSmall: AppTextStyles.captionUppercase,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleMd,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: _buttonMinSize,
          padding: _buttonPadding,
          shape: _buttonShape,
          overlayColor: _noOverlay,
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return AppColors.muted;
            }
            return AppColors.onPrimary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return AppColors.canvasElevated;
            }
            if (s.contains(WidgetState.pressed)) {
              return AppColors.primaryActive;
            }
            return AppColors.primary;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: _buttonMinSize,
          padding: _buttonPadding,
          shape: _buttonShape,
          overlayColor: _noOverlay,
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return AppColors.muted;
            }
            return AppColors.ink;
          }),
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppColors.muted);
            }
            return const BorderSide(color: AppColors.ink);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: _noOverlay,
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) {
              return AppColors.muted;
            }
            return AppColors.ink;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 14),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
        border: _inputBorder(AppColors.hairline),
        enabledBorder: _inputBorder(AppColors.hairline),
        focusedBorder: _inputBorder(AppColors.focusRing),
        errorBorder: _inputBorder(AppColors.warning),
        focusedErrorBorder: _inputBorder(AppColors.warning),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.canvasElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
            AppTextStyles.captionUppercase.copyWith(
                color: s.contains(WidgetState.selected)
                    ? AppColors.ink
                    : AppColors.muted)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.muted)),
      ),
    );
  }
}
