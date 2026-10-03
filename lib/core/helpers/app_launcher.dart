import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppLauncher — Opening links or files externally
///
/// Utility class to navigate to external links or system-default file viewers.
/// Offline-first design with hooks ready for platform channels.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppLauncher {
  /// Opens a web URL externally.
  static Future<bool> launchUrl(String urlString) async {
    AppLogger.info('AppLauncher: Request to launch URL: $urlString');
    // In the future: implement url_launcher package call here.
    return true;
  }

  /// Opens an output converted file using the system default handler/viewer.
  static Future<bool> openFile(String filePath) async {
    AppLogger.info('AppLauncher: Request to open file path: $filePath');
    // In the future: launch file using android platform intent.
    return true;
  }
}
