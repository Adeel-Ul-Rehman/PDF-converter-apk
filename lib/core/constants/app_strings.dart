/// ─────────────────────────────────────────────────────────────────────────────
/// AppStrings — Centralised String Constants
///
/// All user-facing strings live here. Never hardcode strings inline.
/// When i18n (internationalisation) is required, replace values with ARB lookups.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppStrings {
  // ── App ──────────────────────────────────────────────────────────────────────
  static const String appName = 'FluxConvert';
  static const String appTagline = 'Convert anything. Offline. Instantly.';

  // ── Navigation ───────────────────────────────────────────────────────────────
  static const String navConvert = 'Convert';
  static const String navHistory = 'History';
  static const String navStorage = 'Storage';
  static const String navSettings = 'Settings';

  // ── Actions ──────────────────────────────────────────────────────────────────
  static const String actionPickFile = 'Pick File';
  static const String actionConvert = 'Convert';
  static const String actionShare = 'Share';
  static const String actionDelete = 'Delete';
  static const String actionRetry = 'Retry';
  static const String actionCancel = 'Cancel';
  static const String actionContinue = 'Continue';
  static const String actionClose = 'Close';

  // ── Conversion States ─────────────────────────────────────────────────────────
  static const String stateConverting = 'Converting…';
  static const String stateSuccess = 'Conversion Complete';
  static const String stateFailed = 'Conversion Failed';
  static const String stateCancelled = 'Conversion Cancelled';

  // ── Errors ───────────────────────────────────────────────────────────────────
  static const String errorGeneric = 'An unexpected error occurred.';
  static const String errorFileTooLarge = 'File exceeds the maximum allowed size.';
  static const String errorUnsupportedFormat = 'This file format is not supported.';
  static const String errorPermissionDenied = 'Storage permission denied.';
  static const String errorConversionFailed = 'The conversion could not be completed.';

  // ── Empty States ─────────────────────────────────────────────────────────────
  static const String emptyHistory = 'No conversions yet.';
  static const String emptyHistorySubtitle = 'Your converted files will appear here.';
  static const String emptyStorage = 'No files in storage.';
}
