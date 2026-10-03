import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/constants/app_elevations.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppThemeExtension — Custom Material 3 Design Tokens
///
/// Attaches custom design tokens (spacing, radius, elevations) to [ThemeData]
/// so developers can access them directly via `Theme.of(context)`.
/// ─────────────────────────────────────────────────────────────────────────────
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusFull,
    required this.elevationNone,
    required this.elevationSm,
    required this.elevationMd,
    required this.elevationLg,
  });

  factory AppThemeExtension.light() => const AppThemeExtension(
        spaceXs: AppDimensions.spaceXs,
        spaceSm: AppDimensions.spaceSmall,
        spaceMd: AppDimensions.spaceMedium,
        spaceLg: AppDimensions.spaceLarge,
        spaceXl: AppDimensions.spaceXl,
        radiusSm: AppBorderRadius.sm,
        radiusMd: AppBorderRadius.md,
        radiusLg: AppBorderRadius.lg,
        radiusFull: AppBorderRadius.full,
        elevationNone: AppElevations.none,
        elevationSm: AppElevations.sm,
        elevationMd: AppElevations.md,
        elevationLg: AppElevations.lg,
      );

  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusFull;

  final double elevationNone;
  final double elevationSm;
  final double elevationMd;
  final double elevationLg;

  @override
  AppThemeExtension copyWith({
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusFull,
    double? elevationNone,
    double? elevationSm,
    double? elevationMd,
    double? elevationLg,
  }) => AppThemeExtension(
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusFull: radiusFull ?? this.radiusFull,
      elevationNone: elevationNone ?? this.elevationNone,
      elevationSm: elevationSm ?? this.elevationSm,
      elevationMd: elevationMd ?? this.elevationMd,
      elevationLg: elevationLg ?? this.elevationLg,
    );

  @override
  AppThemeExtension lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t),
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t),
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t),
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t),
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t),
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t),
      radiusFull: lerpDouble(radiusFull, other.radiusFull, t),
      elevationNone: lerpDouble(elevationNone, other.elevationNone, t),
      elevationSm: lerpDouble(elevationSm, other.elevationSm, t),
      elevationMd: lerpDouble(elevationMd, other.elevationMd, t),
      elevationLg: lerpDouble(elevationLg, other.elevationLg, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Extension helper to retrieve the design tokens via BuildContext.
extension AppThemeContextX on BuildContext {
  AppThemeExtension get designTokens =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
