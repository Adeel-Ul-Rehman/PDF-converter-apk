import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/constants/app_border_radius.dart';
import 'package:flux_convert/core/constants/app_dimensions.dart';
import 'package:flux_convert/core/routing/app_routes.dart';
import 'package:flux_convert/core/theme/app_colors.dart';
import 'package:flux_convert/features/home/presentation/widgets/format_selector_bottom_sheet.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ShellScaffold — Persistent Custom Bottom Navigation Shell
///
/// Wraps the GoRouter ShellRoute child and provides a highlighted center "+"
/// action button between Home and Files options.
///
/// Back button behaviour:
///   • Files tab  → always navigate to Home tab
///   • Home tab   → show exit confirmation dialog (Cancel / Exit)
///   • Exit confirmed → SystemNavigator.pop()
/// ─────────────────────────────────────────────────────────────────────────────
class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  bool _isExitDialogShowing = false;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.history)) return 1;
    return 0; // Default to Home
  }

  Future<void> _handleBack(BuildContext context) async {
    final activeIndex = _selectedIndex(context);

    // ── Files tab: go back to Home ────────────────────────────────────────────
    if (activeIndex == 1) {
      context.go(AppRoutes.home);
      return;
    }

    // ── Home tab: show exit confirmation dialog ───────────────────────────────
    if (_isExitDialogShowing) return; // Prevent duplicate dialogs
    _isExitDialogShowing = true;

    final shouldExit = await _showExitDialog(context);
    _isExitDialogShowing = false;

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorScheme.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: AppColorScheme.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Close App?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit FluxConvert?',
          style: TextStyle(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Cancel button — stay in the app
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          // Exit button — close the app
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _selectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 72,
            margin: const EdgeInsets.fromLTRB(
              AppDimensions.s16,
              0,
              AppDimensions.s16,
              AppDimensions.s12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColorScheme.cardDark : AppColorScheme.cardLight,
              borderRadius: AppBorderRadius.radiusXl,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? AppColorScheme.borderDark : AppColorScheme.borderLight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Bottom navbar buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Tab 1: Home
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go(AppRoutes.home),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              activeIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                              color: activeIndex == 0
                                  ? AppColorScheme.primaryBlueStart
                                  : (isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.textSecondaryLight),
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Home',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: activeIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                color: activeIndex == 0
                                    ? AppColorScheme.primaryBlueStart
                                    : (isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Middle spacing placeholder for center FAB
                    const SizedBox(width: 60),

                    // Tab 2: Files
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go(AppRoutes.history),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              activeIndex == 1 ? Icons.insert_drive_file_rounded : Icons.insert_drive_file_outlined,
                              color: activeIndex == 1
                                  ? AppColorScheme.primaryBlueStart
                                  : (isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.textSecondaryLight),
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Files',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: activeIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                color: activeIndex == 1
                                    ? AppColorScheme.primaryBlueStart
                                    : (isDark ? AppColorScheme.textSecondaryDark : AppColorScheme.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Highlighted Floating "+" button in the center
                Positioned(
                  top: -24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const FormatSelectorBottomSheet(),
                        );
                      },
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppColorScheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColorScheme.primaryBlueStart.withAlpha(90),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
