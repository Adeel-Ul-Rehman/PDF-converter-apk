import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_elevations.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';
import 'package:flux_convert/core/theme/app_theme_extensions.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppTheme — Material 3 Theme Configuration
///
/// Design system configuration for Light Theme. Includes all component themes:
/// buttons, cards, dialogs, bottom sheets, snackbars, and text inputs.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppTheme {
  // ── Light Theme ───────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        textTheme: AppTextStyles.textTheme,

        // ── Custom Design Tokens Extension ───────────────────────────────────
        extensions: [
          AppThemeExtension.light(),
        ],

        // ── App Bar ──────────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColorScheme.surfaceLight,
          foregroundColor: AppColorScheme.onSurfaceLight,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: AppColorScheme.surfaceLight,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),

        // ── Bottom Navigation Bar ────────────────────────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColorScheme.surfaceLight,
          indicatorColor: AppColorScheme.primary.withAlpha(30),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelMedium.copyWith(
                color: AppColorScheme.primary,
                fontWeight: FontWeight.w700,
              );
            }
            return AppTextStyles.labelMedium.copyWith(
              color: AppColorScheme.onSurfaceLight.withAlpha(180),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: AppColorScheme.primary,
                size: 24,
              );
            }
            return IconThemeData(
              color: AppColorScheme.onSurfaceLight.withAlpha(180),
              size: 24,
            );
          }),
          elevation: AppElevations.lg,
          height: 72,
        ),

        // ── Filled Button ────────────────────────────────────────────────────
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColorScheme.primary,
            foregroundColor: AppColorScheme.onPrimary,
            textStyle: AppTextStyles.labelLarge,
            minimumSize: const Size(120, 48),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.md)),
            ),
          ),
        ),

        // ── Outlined Button ──────────────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColorScheme.primary,
            textStyle: AppTextStyles.labelLarge,
            minimumSize: const Size(120, 48),
            side: const BorderSide(color: AppColorScheme.primary, width: 1.5),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.md)),
            ),
          ),
        ),

        // ── Text Button ──────────────────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColorScheme.primary,
            textStyle: AppTextStyles.labelLarge,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.md)),
            ),
          ),
        ),

        // ── Card ─────────────────────────────────────────────────────────────
        cardTheme: const CardThemeData(
          color: AppColorScheme.surfaceLight,
          surfaceTintColor: Colors.transparent,
          elevation: AppElevations.none,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.lg)),
          ),
        ),

        // ── Input Decoration ─────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColorScheme.surfaceVariantLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: const BorderSide(
              color: AppColorScheme.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: const BorderSide(
              color: AppColorScheme.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: const BorderSide(
              color: AppColorScheme.error,
              width: 1.5,
            ),
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColorScheme.onSurfaceLight.withAlpha(100),
          ),
          labelStyle: AppTextStyles.bodyMedium,
          errorStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColorScheme.error,
          ),
        ),

        // ── Chip ─────────────────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColorScheme.surfaceVariantLight,
          labelStyle: AppTextStyles.labelMedium,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.sm)),
          ),
        ),

        // ── Divider ──────────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColorScheme.outlineVariant,
          thickness: 1,
          space: 1,
        ),

        // ── Progress Indicator ────────────────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColorScheme.primary,
          linearTrackColor: AppColorScheme.surfaceVariantLight,
        ),

        // ── Dialog Theme ──────────────────────────────────────────────────────
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColorScheme.surfaceLight,
          elevation: AppElevations.xxl,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.lg)),
          ),
        ),

        // ── Bottom Sheet Theme ────────────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColorScheme.surfaceLight,
          elevation: AppElevations.xl,
          modalElevation: AppElevations.xl,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.lg)),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // ── Snackbar Theme ────────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColorScheme.onSurfaceLight,
          actionTextColor: AppColorScheme.primary,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColorScheme.white,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.sm)),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // ── Scaffold ────────────────────────────────────────────────Scaffold
        scaffoldBackgroundColor: AppColorScheme.backgroundLight,

        // ── Icon ──────────────────────────────────────────────────────────────
        iconTheme: const IconThemeData(
          color: AppColorScheme.onSurfaceLight,
          size: 24,
        ),
      );

  // ── Color Schemes ─────────────────────────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,

    primary: AppColorScheme.primary,
    onPrimary: AppColorScheme.onPrimary,
    primaryContainer: Color(0xFFE8E0FF),
    onPrimaryContainer: Color(0xFF1A0060),

    secondary: AppColorScheme.secondary,
    onSecondary: AppColorScheme.onSecondary,
    secondaryContainer: Color(0xFFB8F5E8),
    onSecondaryContainer: Color(0xFF002119),

    tertiary: AppColorScheme.tertiary,
    onTertiary: AppColorScheme.onTertiary,
    tertiaryContainer: Color(0xFFFFDAD6),
    onTertiaryContainer: Color(0xFF410002),

    error: AppColorScheme.error,
    onError: AppColorScheme.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    surface: AppColorScheme.surfaceLight,
    onSurface: AppColorScheme.onSurfaceLight,
    surfaceContainerHighest: AppColorScheme.surfaceVariantLight,
    onSurfaceVariant: Color(0xFF49454F),
    outline: AppColorScheme.outline,
    outlineVariant: AppColorScheme.outlineVariant,

    shadow: AppColorScheme.shadow,
    scrim: AppColorScheme.scrim,
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFCFBCFF),
  );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        textTheme: AppTextStyles.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        extensions: [
          AppThemeExtension.light(),
        ],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF1E1E1E),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          indicatorColor: AppColorScheme.primary.withAlpha(50),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              );
            }
            return AppTextStyles.labelMedium.copyWith(
              color: Colors.white70,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: Colors.white,
                size: 24,
              );
            }
            return const IconThemeData(
              color: Colors.white70,
              size: 24,
            );
          }),
          elevation: AppElevations.lg,
          height: 72,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColorScheme.primary,
            foregroundColor: Colors.white,
            textStyle: AppTextStyles.labelLarge,
            minimumSize: const Size(120, 48),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.md)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: AppTextStyles.labelLarge,
            minimumSize: const Size(120, 48),
            side: const BorderSide(color: Colors.white38, width: 1.5),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.md)),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: AppTextStyles.labelLarge,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.md)),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
          elevation: AppElevations.none,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.lg)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: const BorderSide(
              color: AppColorScheme.primary,
              width: 1.5,
            ),
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white38,
          ),
          labelStyle: AppTextStyles.bodyMedium,
          errorStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColorScheme.error,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2C2C2C),
          labelStyle: AppTextStyles.labelMedium,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.sm)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF3A3A3C),
          thickness: 1,
          space: 1,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColorScheme.primary,
          linearTrackColor: Color(0xFF2C2C2C),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: AppElevations.xxl,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.lg)),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: AppElevations.xl,
          modalElevation: AppElevations.xl,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.lg)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.white,
          actionTextColor: AppColorScheme.primary,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: Colors.black,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppBorderRadius.sm)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,

    primary: AppColorScheme.primary,
    onPrimary: AppColorScheme.onPrimary,
    primaryContainer: Color(0xFF3B2F7E),
    onPrimaryContainer: Color(0xFFE8E0FF),

    secondary: AppColorScheme.secondary,
    onSecondary: AppColorScheme.onSecondary,
    secondaryContainer: Color(0xFF00503E),
    onSecondaryContainer: Color(0xFFB8F5E8),

    tertiary: AppColorScheme.tertiary,
    onTertiary: AppColorScheme.onTertiary,
    tertiaryContainer: Color(0xFF93000A),
    onTertiaryContainer: Color(0xFFFFDAD6),

    error: AppColorScheme.error,
    onError: AppColorScheme.white,
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE0E0E0),
    surfaceContainerHighest: Color(0xFF2C2C2C),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF8E8E93),
    outlineVariant: Color(0xFF48484A),

    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE3E2E6),
    onInverseSurface: Color(0xFF1A1C1E),
    inversePrimary: AppColorScheme.primary,
  );
}
