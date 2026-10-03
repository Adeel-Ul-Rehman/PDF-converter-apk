import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flux_convert/features/settings/presentation/providers/settings_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DeveloperPage — Developer Options and Advanced Diagnostics
/// ─────────────────────────────────────────────────────────────────────────────
class DeveloperPage extends ConsumerWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final controller = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: const ReusableAppBar(
        title: 'Developer Options',
      ),
      body: SafeArea(
        child: ListView(
          padding: AppDimensions.paddingScreenContent,
          children: [
            AppDimensions.h12,
            Text(
              'Developer Configuration',
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
                  SettingTile(
                    title: 'Developer Mode',
                    description: 'Unlock verbose tools and debug panels.',
                    icon: Icons.developer_mode_rounded,
                    trailing: Switch.adaptive(
                      value: settings.developerMode,
                      onChanged: (value) => unawaited(
                        controller.setBool(key: 'developerMode', value: value),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SettingTile(
                    title: 'Verbose Debug Logging',
                    description: 'Log all low-level activities to system console.',
                    icon: Icons.bug_report_rounded,
                    trailing: Switch.adaptive(
                      value: settings.enableDebugLogs,
                      onChanged: (value) => unawaited(
                        controller.setBool(key: 'enableDebugLogs', value: value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppDimensions.h24,

            Text(
              'Diagnostics Info',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColorScheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDimensions.h8,
            const PrimaryCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _DiagnosticRow(
                    label: 'Database Sync Mode',
                    value: 'SQLite WAL (Write-Ahead Logging)',
                  ),
                  Divider(height: 1),
                  _DiagnosticRow(
                    label: 'System Isolation',
                    value: 'Fully Sandboxed (Android Storage-Access)',
                  ),
                  Divider(height: 1),
                  _DiagnosticRow(
                    label: 'Routing State',
                    value: 'Declarative GoRouter (v10.x)',
                  ),
                  Divider(height: 1),
                  _DiagnosticRow(
                    label: 'Logging Engine',
                    value: 'Console (FCLogger)',
                  ),
                ],
              ),
            ),
            AppDimensions.h24,

            Text(
              'Developer Actions',
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
                  ListTile(
                    title: Text(
                      'View & Export System Error Logs',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'View, filter, and share production diagnostic logs',
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
                      context.push(AppRoutes.settingsErrorLogs);
                    },
                  ),
                ],
              ),
            ),
            AppDimensions.h40,
          ],
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.s16,
        vertical: AppDimensions.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColorScheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppDimensions.h4,
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
}
