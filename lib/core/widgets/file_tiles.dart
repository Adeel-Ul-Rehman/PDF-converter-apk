import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/constants/app_icons.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';
import 'package:flux_convert/core/widgets/chips_and_badges.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FileTile — Simple Selected File Summary row
/// ─────────────────────────────────────────────────────────────────────────────
class FileTile extends StatelessWidget {
  const FileTile({
    required this.name,
    required this.size,
    required this.categoryIcon,
    this.onDelete,
    super.key,
  });

  final String name;
  final String size;
  final IconData categoryIcon;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppDimensions.s12),
      decoration: BoxDecoration(
        color: AppColorScheme.surface,
        borderRadius: AppBorderRadius.radiusMd,
        border: Border.all(color: AppColorScheme.border.withAlpha(120)),
      ),
      child: Row(
        children: [
          Icon(categoryIcon, color: AppColorScheme.textSecondary, size: 28),
          AppDimensions.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppDimensions.h2,
                Text(size, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(AppIcons.delete, color: AppColorScheme.danger),
              onPressed: onDelete,
            ),
        ],
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// HistoryTile — Conversion Job Log Row
/// ─────────────────────────────────────────────────────────────────────────────
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    required this.inputName,
    required this.outputName,
    required this.inputFormat,
    required this.outputFormat,
    required this.dateText,
    required this.isSuccess,
    this.onTap,
    super.key,
  });

  final String inputName;
  final String outputName;
  final String inputFormat;
  final String outputFormat;
  final String dateText;
  final bool isSuccess;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.s6),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Tag(label: inputFormat.toUpperCase()),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_rounded, size: 12),
                      ),
                      Tag(label: outputFormat.toUpperCase()),
                    ],
                  ),
                  StatusBadge(
                    statusText: isSuccess ? 'Success' : 'Failed',
                    type: isSuccess ? StatusType.success : StatusType.danger,
                  ),
                ],
              ),
              AppDimensions.h12,
              Text(
                isSuccess ? outputName : inputName,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppDimensions.h6,
              Text(
                dateText,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionTile — Progress indicator row for active jobs
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionTile extends StatelessWidget {
  const ConversionTile({
    required this.name,
    required this.progressPercent,
    required this.formatTag,
    this.onCancel,
    super.key,
  });

  final String name;
  final int progressPercent;
  final String formatTag;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final progress = progressPercent / 100.0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColorScheme.surface,
        borderRadius: AppBorderRadius.radiusLg,
        border: Border.all(color: AppColorScheme.border.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Tag(label: formatTag.toUpperCase()),
                  AppDimensions.w8,
                  Text(
                    name,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (onCancel != null && progressPercent < 100)
                IconButton(
                  icon: const Icon(AppIcons.close, size: 18),
                  onPressed: onCancel,
                ),
            ],
          ),
          AppDimensions.h12,
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppBorderRadius.radiusFull,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColorScheme.border.withAlpha(80),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColorScheme.primaryBlueStart),
                  ),
                ),
              ),
              AppDimensions.w12,
              Text(
                '$progressPercent%',
                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
