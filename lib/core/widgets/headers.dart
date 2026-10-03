import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SectionHeader — Reusable Section Label Header
/// ─────────────────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.title,
              ),
              if (subtitle != null) ...[
                AppDimensions.h4,
                Text(
                  subtitle!,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// TitleHeader — Main Page Bold Title Header
/// ─────────────────────────────────────────────────────────────────────────────
class TitleHeader extends StatelessWidget {
  const TitleHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTextStyles.headline,
        ),
        AppDimensions.h6,
        Text(
          subtitle,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// AnimatedDivider — Dynamic Divider with Accent Highlight
/// ─────────────────────────────────────────────────────────────────────────────
class AnimatedDivider extends StatelessWidget {
  const AnimatedDivider({super.key});

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        Divider(
          color: AppColorScheme.border.withAlpha(100),
          thickness: 1,
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 48,
            decoration: const BoxDecoration(
              gradient: AppColorScheme.primaryGradient,
              borderRadius: AppBorderRadius.radiusFull,
            ),
          ),
        ),
      ],
    );
}
