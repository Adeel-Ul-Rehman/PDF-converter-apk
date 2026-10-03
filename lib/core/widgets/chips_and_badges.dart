import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ModernChip — Interactive Action Chip
/// ─────────────────────────────────────────────────────────────────────────────
class ModernChip extends StatelessWidget {
  const ModernChip({
    required this.label,
    this.isSelected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.radiusFull,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s16,
          vertical: AppDimensions.s8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorScheme.primaryBlueStart
              : AppColorScheme.surface,
          borderRadius: AppBorderRadius.radiusFull,
          border: Border.all(
            color: isSelected
                ? AppColorScheme.primaryBlueStart
                : AppColorScheme.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? Colors.white : AppColorScheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Badge — Notification Numeric Alert Bubble
/// ─────────────────────────────────────────────────────────────────────────────
class Badge extends StatelessWidget {
  const Badge({
    required this.count,
    this.color = AppColorScheme.danger,
    super.key,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// StatusBadge — Semantic Status Tag
/// ─────────────────────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.statusText,
    required this.type,
    super.key,
  });

  final String statusText;
  final StatusType type;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (type) {
      StatusType.success => (AppColorScheme.success.withAlpha(25), AppColorScheme.success),
      StatusType.warning => (AppColorScheme.warning.withAlpha(25), AppColorScheme.warning),
      StatusType.danger => (AppColorScheme.danger.withAlpha(25), AppColorScheme.danger),
      StatusType.info => (AppColorScheme.accent.withAlpha(25), AppColorScheme.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s8, vertical: AppDimensions.s4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppBorderRadius.radiusXs,
        border: Border.all(color: textColor.withAlpha(80)),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

enum StatusType { success, warning, danger, info }

/// ─────────────────────────────────────────────────────────────────────────────
/// Tag — Visual Metadata Tag
/// ─────────────────────────────────────────────────────────────────────────────
class Tag extends StatelessWidget {
  const Tag({
    required this.label,
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s8, vertical: AppDimensions.s4),
      decoration: BoxDecoration(
        color: AppColorScheme.surface,
        borderRadius: AppBorderRadius.radiusXs,
        border: Border.all(color: AppColorScheme.border.withAlpha(150)),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(fontSize: 10),
      ),
    );
}
