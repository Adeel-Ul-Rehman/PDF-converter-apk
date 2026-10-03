import 'package:flutter/material.dart';

import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AboutPage — Premium Material 3 About Screen
/// ─────────────────────────────────────────────────────────────────────────────
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const ReusableAppBar(
        title: 'About FluxConvert',
      ),
      body: SafeArea(
        child: ListView(
          padding: AppDimensions.paddingScreenContent,
          children: [
            AppDimensions.h24,
            // App Logo and Header Card
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColorScheme.primary.withAlpha(20),
                      borderRadius: AppBorderRadius.radiusXl,
                      border: Border.all(
                        color: AppColorScheme.primary.withAlpha(51),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.transform_rounded,
                      size: 48,
                      color: AppColorScheme.primary,
                    ),
                  ),
                  AppDimensions.h16,
                  Text(
                    AppConfig.appName,
                    style: AppTextStyles.headline.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  AppDimensions.h4,
                  Text(
                    'Offline File Conversion Made Simple',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AppDimensions.h32,

            // Version Information Card
            Text(
              'Application Info',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColorScheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDimensions.h8,
            PrimaryCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _InfoRow(
                    label: 'Version',
                    value: AppConfig.appVersion,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    label: 'Build Number',
                    value: AppConfig.appBuildNumber.toString(),
                  ),
                  const Divider(height: 1),
                  const _InfoRow(
                    label: 'Package Name',
                    value: AppConfig.appPackageName,
                  ),
                  const Divider(height: 1),
                  const _InfoRow(
                    label: 'Operating Mode',
                    value: '100% Offline-First',
                    valueColor: AppColorScheme.primary,
                  ),
                ],
              ),
            ),
            AppDimensions.h24,

            // Developer & License Information Card
            Text(
              'Credits & Legal',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColorScheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDimensions.h8,
            PrimaryCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _InfoRow(
                    label: 'Developer',
                    value: 'FluxConvert Team',
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Open Source Licenses',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Third-party software components and attributions',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColorScheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColorScheme.textSecondary,
                    ),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: AppConfig.appName,
                      applicationVersion: AppConfig.appVersion,
                      applicationIcon: const Padding(
                        padding: EdgeInsets.all(AppDimensions.s12),
                        child: Icon(
                          Icons.transform_rounded,
                          size: 40,
                          color: AppColorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Privacy Policy',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Local data usage and privacy details',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColorScheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColorScheme.textSecondary,
                    ),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Privacy Policy'),
                          content: const Text(
                            'FluxConvert operates 100% offline. No analytics, '
                            'tracking, or telemetry is gathered, collected, or '
                            'transmitted. All conversions and data reside solely on '
                            'your device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            AppDimensions.h40,

            // Copyright Text
            Center(
              child: Text(
                '© 2026 FluxConvert Team. All rights reserved.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColorScheme.textSecondary.withAlpha(153),
                ),
              ),
            ),
            AppDimensions.h24,
          ],
        ),
      ),
    );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.s16,
        vertical: AppDimensions.s16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColorScheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
}
