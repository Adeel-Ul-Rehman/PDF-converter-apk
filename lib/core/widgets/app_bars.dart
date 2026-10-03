import 'package:flutter/material.dart';

import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';
import 'package:flux_convert/core/widgets/buttons.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ReusableAppBar — Minimal Styled Platform AppBar
/// ─────────────────────────────────────────────────────────────────────────────
class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ReusableAppBar({
    required this.title,
    this.showBackButton = true,
    this.actions,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => AppBar(
      title: Text(title, style: AppTextStyles.titleLarge),
      leading: showBackButton
          ? const Center(child: CustomBackButton())
          : null,
      actions: actions,
      backgroundColor: AppColorScheme.background,
      elevation: 0,
      scrolledUnderElevation: 1,
    );

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// GradientAppBar — Premium Gradient Backdrop Header
/// ─────────────────────────────────────────────────────────────────────────────
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    required this.title,
    this.showBackButton = true,
    this.actions,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColorScheme.primaryGradient,
      ),
      child: SafeArea(
        child: Container(
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s8),
          child: Row(
            children: [
              if (showBackButton)
                const CustomBackButton(
                  backgroundColor: Colors.transparent,
                  iconColor: Colors.white,
                )
              else
                AppDimensions.w16,
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );

  @override
  Size get preferredSize => const Size.fromHeight(56.0 + 24.0); // Accommodate safe area heights
}
