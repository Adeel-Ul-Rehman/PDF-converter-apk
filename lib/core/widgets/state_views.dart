import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/constants/app_icons.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';
import 'package:flux_convert/core/widgets/buttons.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// EmptyState — Generic Blank Screen Content Placeholder
///
/// Designed to cover: History Empty, No Files, No Internet, Permission Missing,
/// Search Empty, Nothing Found.
/// ─────────────────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    required this.icon,
    this.actionButton,
    super.key,
  });

  // ── Factory presets for typical app scenarios ─────────────────────────────
  
  factory EmptyState.historyEmpty() => const EmptyState(
        title: 'No Conversion History',
        message: 'Your converted files will appear here once ready.',
        icon: AppIcons.history,
      );

  factory EmptyState.noFiles() => const EmptyState(
        title: 'Storage Directory Empty',
        message: 'No files are currently stored locally.',
        icon: AppIcons.storage,
      );

  factory EmptyState.noInternet({VoidCallback? onRetry}) => EmptyState(
        title: 'Connection Offline',
        message: 'Network connection required for online conversions.',
        icon: Icons.wifi_off_rounded,
        actionButton: onRetry != null
            ? CustomOutlinedButton(onPressed: onRetry, child: const Text('Try Again'))
            : null,
      );

  factory EmptyState.permissionMissing({required VoidCallback onRequest}) => EmptyState(
        title: 'Permission Denied',
        message: 'Enable file access permissions in settings to pick files.',
        icon: Icons.lock_outline_rounded,
        actionButton: GradientButton(
          onPressed: onRequest,
          child: const Text('Grant Permission'),
        ),
      );

  factory EmptyState.searchEmpty() => const EmptyState(
        title: 'No Matching Results',
        message: 'Try adjusting your search keywords.',
        icon: AppIcons.search,
      );

  final String title;
  final String message;
  final IconData icon;
  final Widget? actionButton;

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.s20),
              decoration: BoxDecoration(
                color: AppColorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColorScheme.border.withAlpha(80), width: 1.5),
              ),
              child: Icon(icon, size: 64, color: AppColorScheme.textSecondary.withAlpha(120)),
            ),
            AppDimensions.h24,
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            AppDimensions.h8,
            Text(
              message,
              style: AppTextStyles.subtitle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              AppDimensions.h24,
              actionButton!,
            ],
          ],
        ),
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ErrorStateWidget — Semantic Error Block with Action Redirect
///
/// Designed to cover: Storage Error, Unknown Error, Permission Error,
/// Conversion Error, File Too Large, Unsupported File.
/// ─────────────────────────────────────────────────────────────────────────────
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.title,
    required this.technicalDetails,
    required this.onRetry,
    this.icon = AppIcons.error,
    super.key,
  });

  // ── Factory presets ───────────────────────────────────────────────────────
  
  factory ErrorStateWidget.storageError({required VoidCallback onRetry}) => ErrorStateWidget(
        title: 'Disk Write Error',
        technicalDetails: 'Insufficient storage space or local path block.',
        onRetry: onRetry,
      );

  factory ErrorStateWidget.permissionError({required VoidCallback onRetry}) => ErrorStateWidget(
        title: 'Access Blocked',
        technicalDetails: 'Android system storage permission denied.',
        onRetry: onRetry,
      );

  factory ErrorStateWidget.conversionError({required VoidCallback onRetry}) => ErrorStateWidget(
        title: 'Conversion Failed',
        technicalDetails: 'Internal decoder encountered unexpected byte markers.',
        onRetry: onRetry,
      );

  factory ErrorStateWidget.fileTooLarge({required VoidCallback onRetry}) => ErrorStateWidget(
        title: 'File Too Large',
        technicalDetails: 'Upload exceeds the supported limit of 100 MB.',
        onRetry: onRetry,
      );

  factory ErrorStateWidget.unsupportedFile({required VoidCallback onRetry}) => ErrorStateWidget(
        title: 'Unsupported Type',
        technicalDetails: 'Specified extension type is not in the supported formats list.',
        onRetry: onRetry,
      );

  final String title;
  final String technicalDetails;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColorScheme.danger),
            AppDimensions.h16,
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(color: AppColorScheme.danger),
              textAlign: TextAlign.center,
            ),
            AppDimensions.h8,
            Text(
              technicalDetails,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            AppDimensions.h24,
            CustomOutlinedButton(
              onPressed: onRetry,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.retry, size: 18),
                  AppDimensions.w6,
                  Text('Retry Action'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SuccessStateWidget — Playful Success/Complete Screen Content
/// ─────────────────────────────────────────────────────────────────────────────
class SuccessStateWidget extends StatelessWidget {
  const SuccessStateWidget({
    required this.title,
    required this.message,
    required this.onContinue,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.success, size: 72, color: AppColorScheme.success),
            AppDimensions.h20,
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(color: AppColorScheme.success),
              textAlign: TextAlign.center,
            ),
            AppDimensions.h8,
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            AppDimensions.h32,
            GradientButton(
              onPressed: onContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
}
