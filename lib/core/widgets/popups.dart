import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppPopups — Unified Alert Modal Interfaces
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppPopups {
  /// General Confirmation Modal
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel, style: const TextStyle(color: AppColorScheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel, style: const TextStyle(color: AppColorScheme.primaryBlueStart, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

  /// Specialized Danger/Delete Confirmation Modal
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required String message,
  }) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColorScheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColorScheme.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

  /// Permission Request Dialogue
  static Future<bool?> showPermissionDialog({
    required BuildContext context,
    required VoidCallback onOpenSettings,
  }) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          'This action requires device file storage access. Grant permission in system settings.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColorScheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onOpenSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: AppColorScheme.primaryBlueStart, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

  /// Bottom Modal Sheet container
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget child,
  }) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.s24,
            vertical: AppDimensions.s20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColorScheme.border,
                  borderRadius: AppBorderRadius.radiusFull,
                ),
              ),
              AppDimensions.h20,
              child,
            ],
          ),
        ),
      ),
    );

  /// Standard Floating SnackBar
  static void showSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColorScheme.danger : AppColorScheme.textPrimary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppDimensions.s16),
      shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusSm),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Standard Transient Toast Message Overlay
  static void showToast({
    required BuildContext context,
    required String message,
  }) {
    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColorScheme.textPrimary.withAlpha(220),
                borderRadius: AppBorderRadius.radiusFull,
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(seconds: 2), overlay.remove);
  }
}
