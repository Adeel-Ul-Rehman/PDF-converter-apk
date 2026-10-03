import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// InformationTile — Raw Metadata View
/// ─────────────────────────────────────────────────────────────────────────────
class InformationTile extends StatelessWidget {
  const InformationTile({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FeatureTile — Large Feature Card
/// ─────────────────────────────────────────────────────────────────────────────
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.s12),
                decoration: const BoxDecoration(
                  gradient: AppColorScheme.primaryGradient,
                  borderRadius: AppBorderRadius.radiusMd,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              AppDimensions.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.title),
                    AppDimensions.h4,
                    Text(description, style: AppTextStyles.subtitle.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SettingTile — Parameter Configuration Tile
/// ─────────────────────────────────────────────────────────────────────────────
class SettingTile extends StatelessWidget {
  const SettingTile({
    required this.title,
    required this.description,
    required this.icon,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColorScheme.textSecondary),
      title: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(description, style: AppTextStyles.caption),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16, vertical: AppDimensions.s4),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// OptionTile — Selectable Parameter Value Tile
/// ─────────────────────────────────────────────────────────────────────────────
class OptionTile extends StatelessWidget {
  const OptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final unselectedBg = theme.colorScheme.surfaceContainerHighest;
    final unselectedBorder = theme.colorScheme.outlineVariant;
    final unselectedText = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.s6),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.radiusMd,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.s16),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withAlpha(20) : unselectedBg,
            borderRadius: AppBorderRadius.radiusMd,
            border: Border.all(
              color: isSelected ? primaryColor : unselectedBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant,
                    ),
                    AppDimensions.w12,
                  ],
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? primaryColor : unselectedText,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CustomListTile — Clean Generic Modular List Element
/// ─────────────────────────────────────────────────────────────────────────────
class CustomListTile extends StatelessWidget {
  const CustomListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
        color: AppColorScheme.card,
        border: Border(bottom: BorderSide(color: AppColorScheme.border.withAlpha(100))),
      ),
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16, vertical: AppDimensions.s8),
      ),
    );
}
