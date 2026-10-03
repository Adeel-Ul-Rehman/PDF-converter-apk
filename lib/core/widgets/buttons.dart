import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/constants/app_icons.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/core/theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GradientButton — Brand Gradient Call-to-Action
///
/// Supports loading states, disabled state, tap animations, and haptic feedback.
/// ─────────────────────────────────────────────────────────────────────────────
class GradientButton extends StatefulWidget {
  const GradientButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isDisabled = false,
    this.gradient = AppColorScheme.primaryGradient,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isDisabled;
  final Gradient gradient;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _scale = 0.96);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 48,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: enabled ? widget.gradient : null,
              color: enabled ? null : AppColorScheme.disabled.withAlpha(80),
              borderRadius: AppBorderRadius.radiusMd,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : DefaultTextStyle(
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                    child: widget.child,
                  ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CustomOutlinedButton — Styled Minimal Outlined Action
/// ─────────────────────────────────────────────────────────────────────────────
class CustomOutlinedButton extends StatelessWidget {
  const CustomOutlinedButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isDisabled = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final enabled = !isDisabled && !isLoading && onPressed != null;

    return OutlinedButton(
      onPressed: enabled ? () {
        HapticFeedback.lightImpact();
        onPressed!();
      } : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: enabled ? AppColorScheme.primaryBlueStart : AppColorScheme.disabled,
          width: 1.5,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusMd,
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : child,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CustomIconButton — Circle Icon Action Button
/// ─────────────────────────────────────────────────────────────────────────────
class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
      onPressed: onPressed != null ? () {
        HapticFeedback.selectionClick();
        onPressed!();
      } : null,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColorScheme.surface,
        foregroundColor: iconColor ?? AppColorScheme.textPrimary,
        padding: const EdgeInsets.all(AppDimensions.s12),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: 20),
    );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CustomBackButton — Unified Platform-Adaptive Exit Trigger
/// ─────────────────────────────────────────────────────────────────────────────
class CustomBackButton extends StatelessWidget {
  const CustomBackButton({
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    super.key,
  });

  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => CustomIconButton(
      icon: AppIcons.back,
      tooltip: 'Back',
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      onPressed: onPressed ?? () {
        Navigator.maybePop(context);
      },
    );
}
