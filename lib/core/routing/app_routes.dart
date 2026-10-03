/// ─────────────────────────────────────────────────────────────────────────────
/// AppRoutes — Route Path & Name Constants
///
/// Centralized route definitions for Splash, Home, Converter, History, Settings.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppRoutes {
  // ── Splash ─────────────────────────────────────────────────────────────────
  static const String splash = '/splash';
  static const String splashName = 'splash';

  // ── Home / Shell Container ─────────────────────────────────────────────────
  static const String home = '/';
  static const String homeName = 'home';

  // ── Tabs ───────────────────────────────────────────────────────────────────
  static const String converter = '/converter';
  static const String converterName = 'converter';

  static const String history = '/history';
  static const String historyName = 'history';

  static const String settings = '/settings';
  static const String settingsName = 'settings';

  static const String settingsAbout = '/settings/about';
  static const String settingsAboutName = 'settings_about';

  static const String settingsDeveloper = '/settings/developer';
  static const String settingsDeveloperName = 'settings_developer';

  static const String settingsErrorLogs = '/settings/error-logs';
  static const String settingsErrorLogsName = 'settings_error_logs';

  static const String allTools = '/all-tools';
  static const String allToolsName = 'all_tools';

  static const String signatureEditor = '/signature-editor';
  static const String signatureEditorName = 'signature_editor';

  static const String doodle = '/doodle';
  static const String doodleName = 'doodle';

  static const String textEditor = '/text-editor';
  static const String textEditorName = 'text_editor';

  // ── Image Selection ────────────────────────────────────────────────────────
  static const String imageSelection = '/image-selection';
  static const String imageSelectionName = 'image_selection';

  // ── Image Editor ───────────────────────────────────────────────────────────
  static const String imageEditor = '/image-editor';
  static const String imageEditorName = 'image_editor';

  // ── Image Preview & Reorder Sorting ────────────────────────────────────────
  static const String imagePreview = '/image-preview';
  static const String imagePreviewName = 'image_preview';

  static const String imageSort = '/image-sort';
  static const String imageSortName = 'image_sort';

  // ── Conversion Success ─────────────────────────────────────────────────────
  static const String conversionSuccess = '/conversion-success';
  static const String conversionSuccessName = 'conversion_success';

  // ── PDF Viewer ─────────────────────────────────────────────────────────────
  static const String pdfViewer = '/pdf-viewer';
  static const String pdfViewerName = 'pdf_viewer';

  // ── Smart Scan ─────────────────────────────────────────────────────────────
  static const String smartScan = '/smart-scan';
  static const String smartScanName = 'smart_scan';

  static const String smartScanCrop = '/smart-scan-crop';
  static const String smartScanCropName = 'smart_scan_crop';

  static const String smartScanManager = '/smart-scan-manager';
  static const String smartScanManagerName = 'smart_scan_manager';

  static const String smartScanReview = '/smart-scan-review';
  static const String smartScanReviewName = 'smart_scan_review';

  static const String compressPdf = '/compress-pdf';
  static const String compressPdfName = 'compress_pdf';
}
