import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SplashPage — Beautiful Minimal App Intro Screen
///
/// Features fade & scale animations, soft gradient background glow,
/// footer version label, and error-resilient bootstrap simulation.
/// ─────────────────────────────────────────────────────────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimationDurations.slow,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimationCurves.enter,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimationCurves.spring,
      ),
    );

    unawaited(_startAppInit());
  }

  Future<void> _startAppInit() async {
    setState(() {
      _hasError = false;
      _errorMsg = '';
    });
    
    // Play intro animations
    unawaited(_animationController.forward(from: 0.0));

    try {
      // Simulate storage initialization & history database warmup
      await Future<void>.delayed(AppAnimationDurations.splash);
      
      if (!mounted) return;
      // Navigate to Home Dashboard Screen
      context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = 'Failed to load local storage configurations. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.error, size: 64, color: AppColorScheme.danger),
                AppDimensions.h16,
                Text(
                  'Initialization Error',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColorScheme.danger),
                ),
                AppDimensions.h8,
                Text(
                  _errorMsg,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                AppDimensions.h24,
                GradientButton(
                  onPressed: _startAppInit,
                  child: const Text('Retry Launch'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColorScheme.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ── Background Glow Accent ─────────────────────────────────────────
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColorScheme.primaryBlueStart.withAlpha(25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // ── Centered Logo & Brand Content ──────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo container
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppBorderRadius.radiusXl,
                        boxShadow: AppShadows.medium,
                      ),
                      padding: const EdgeInsets.all(AppDimensions.s16),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if asset fails to load
                          return const Icon(
                            AppIcons.convert,
                            size: 48,
                            color: AppColorScheme.primaryBlueStart,
                          );
                        },
                      ),
                    ),
                    AppDimensions.h24,
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.headline.copyWith(
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AppDimensions.h8,
                    Text(
                      'Convert • Simplify • Save',
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                    AppDimensions.h48,
                    // Minimal indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColorScheme.primaryBlueStart,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────────
          Positioned(
            bottom: AppDimensions.s32,
            left: 0,
            right: 0,
            child: Text(
              'Version 1.0.0',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColorScheme.textSecondary.withAlpha(120),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
