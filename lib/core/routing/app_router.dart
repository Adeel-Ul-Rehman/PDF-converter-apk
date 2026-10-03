import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/core/routing/app_routes.dart';
import 'package:flux_convert/core/routing/shell_scaffold.dart';
import 'package:flux_convert/features/converter/presentation/pages/converter_page.dart';
import 'package:flux_convert/features/history/presentation/pages/history_page.dart';
import 'package:flux_convert/features/settings/settings.dart';
import 'package:flux_convert/features/splash/presentation/pages/splash_page.dart';
import 'package:flux_convert/features/home/presentation/pages/home_page.dart';
import 'package:flux_convert/features/home/presentation/pages/all_tools_page.dart';
import 'package:flux_convert/features/home/presentation/pages/signature_editor_page.dart';
import 'package:flux_convert/features/home/presentation/pages/image_selection_page.dart';
import 'package:flux_convert/features/home/presentation/pages/image_editor_page.dart';
import 'package:flux_convert/features/home/presentation/pages/image_preview_page.dart';
import 'package:flux_convert/features/home/presentation/pages/image_sort_page.dart';
import 'package:flux_convert/features/home/presentation/pages/conversion_success_page.dart';
import 'package:flux_convert/features/home/presentation/pages/pdf_viewer_page.dart';
import 'package:flux_convert/features/home/presentation/pages/doodle_page.dart';
import 'package:flux_convert/features/home/presentation/pages/text_editor_page.dart';
import 'package:flux_convert/features/settings/presentation/pages/error_logs_page.dart';
import 'package:flux_convert/features/smart_scan/presentation/pages/smart_scan_page.dart';
import 'package:flux_convert/features/smart_scan/presentation/pages/smart_scan_crop_page.dart';
import 'package:flux_convert/features/smart_scan/presentation/pages/smart_scan_page_manager_page.dart';
import 'package:flux_convert/features/smart_scan/presentation/pages/smart_scan_review_page.dart';
import 'package:flux_convert/features/pdf_compression/presentation/pages/pdf_compression_page.dart';

// FIXED: Comprehensive navigation stack configuration for GoRouter.
// All sub-routes are pushed on top of the Home root route so pressing Back
// pops back through the navigation stack to the previous screen.
abstract final class AppRouter {
  static final GoRouter config = GoRouter(
    initialLocation: AppRoutes.splash,
    observers: [_AppRouteObserver()],
    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
    routes: [
      // ── Splash ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashPage(),
      ),

      // ── Shell Navigation (Home & Files tabs) ──────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          // FIXED: Tab 1: Home Dashboard (Root of the navigation stack)
          GoRoute(
            path: AppRoutes.home,
            name: AppRoutes.homeName,
            builder: (context, state) => const HomePage(),
          ),

          // Tab 2: Files (History)
          GoRoute(
            path: AppRoutes.history,
            name: AppRoutes.historyName,
            builder: (context, state) => const HistoryPage(),
          ),
        ],
      ),

      // ── Root-Level full-screen sub-routes (Pushed to stack) ───────────────
      GoRoute(
        path: AppRoutes.converter,
        name: AppRoutes.converterName,
        builder: (context, state) => const ConverterPage(),
      ),

      GoRoute(
        path: AppRoutes.allTools,
        name: AppRoutes.allToolsName,
        builder: (context, state) => const AllToolsPage(),
      ),

      GoRoute(
        path: AppRoutes.signatureEditor,
        name: AppRoutes.signatureEditorName,
        builder: (context, state) => const SignatureEditorPage(),
      ),

      GoRoute(
        path: AppRoutes.doodle,
        name: AppRoutes.doodleName,
        builder: (context, state) => const DoodlePage(),
      ),

      GoRoute(
        path: AppRoutes.textEditor,
        name: AppRoutes.textEditorName,
        builder: (context, state) => const TextEditorPage(),
      ),

      GoRoute(
        path: AppRoutes.imageSelection,
        name: AppRoutes.imageSelectionName,
        builder: (context, state) {
          final append = state.uri.queryParameters['append'] == 'true';
          return ImageSelectionPage(append: append);
        },
      ),

      GoRoute(
        path: AppRoutes.imageEditor,
        name: AppRoutes.imageEditorName,
        builder: (context, state) => const ImageEditorPage(),
      ),

      GoRoute(
        path: AppRoutes.imagePreview,
        name: AppRoutes.imagePreviewName,
        builder: (context, state) => const ImageToPdfPreviewPage(),
      ),

      GoRoute(
        path: AppRoutes.imageSort,
        name: AppRoutes.imageSortName,
        builder: (context, state) => const ImageSortPage(),
      ),

      GoRoute(
        path: AppRoutes.conversionSuccess,
        name: AppRoutes.conversionSuccessName,
        builder: (context, state) => const ConversionSuccessPage(),
      ),

      GoRoute(
        path: AppRoutes.pdfViewer,
        name: AppRoutes.pdfViewerName,
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return PdfViewerPage(pdfPath: path);
        },
      ),

      GoRoute(
        path: AppRoutes.smartScan,
        name: AppRoutes.smartScanName,
        builder: (context, state) => const SmartScanPage(),
      ),

      GoRoute(
        path: AppRoutes.smartScanCrop,
        name: AppRoutes.smartScanCropName,
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return SmartScanCropPage(imagePath: path);
        },
      ),

      GoRoute(
        path: AppRoutes.smartScanManager,
        name: AppRoutes.smartScanManagerName,
        builder: (context, state) => const SmartScanPageManagerPage(),
      ),

      GoRoute(
        path: AppRoutes.smartScanReview,
        name: AppRoutes.smartScanReviewName,
        builder: (context, state) => const SmartScanReviewPage(),
      ),

      GoRoute(
        path: AppRoutes.compressPdf,
        name: AppRoutes.compressPdfName,
        builder: (context, state) => const PdfCompressionPage(),
      ),

      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'about',
            name: AppRoutes.settingsAboutName,
            builder: (context, state) => const AboutPage(),
          ),
          GoRoute(
            path: 'developer',
            name: AppRoutes.settingsDeveloperName,
            builder: (context, state) => const DeveloperPage(),
          ),
          GoRoute(
            path: 'error-logs',
            name: AppRoutes.settingsErrorLogsName,
            builder: (context, state) => const ErrorLogsPage(),
          ),
        ],
      ),
    ],
  );
}

/// Route observer that logs navigation events in debug mode.
final class _AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.trace('Router: push → ${route.settings.name}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.trace('Router: pop ← ${route.settings.name}');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.trace(
      'Router: replace ${oldRoute?.settings.name} → ${newRoute?.settings.name}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

/// Fallback error page shown when a route cannot be resolved.
class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage({required this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found', style: theme.textTheme.headlineSmall),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
