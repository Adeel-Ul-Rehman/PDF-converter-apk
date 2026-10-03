import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/constants/app_shadows.dart';
import 'package:flux_convert/core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PrimaryCard — Main Container Card
///
/// Features clean white backdrop, smooth round corners, and soft modern shadow.
/// ─────────────────────────────────────────────────────────────────────────────
class PrimaryCard extends StatelessWidget {
  const PrimaryCard({
    required this.child,
    this.padding = AppDimensions.paddingAll16,
    this.margin,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = theme.brightness == Brightness.light
        ? AppColorScheme.border.withAlpha(120)
        : theme.colorScheme.outlineVariant;
    final shadow = theme.brightness == Brightness.light ? AppShadows.light : const <BoxShadow>[];

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppBorderRadius.radiusLg,
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.radiusLg,
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// GlassCard — Glassmorphic Styled Card
///
/// Emulates soft frosted-glass textures using custom alpha opacities.
/// ─────────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = AppDimensions.paddingAll16,
    this.margin,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColorScheme.card.withAlpha(180),
        borderRadius: AppBorderRadius.radiusLg,
        border: Border.all(color: AppColorScheme.card.withAlpha(80), width: 1.5),
        boxShadow: AppShadows.medium,
      ),
      child: child,
    );
}
