import 'package:intl/intl.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DateFormatter — Standardised Date and Time Display
///
/// Ensures all dates and times shown in the app share a unified format structure.
/// Uses the intl package.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class DateFormatter {
  /// e.g. "03 Aug 2026"
  static String formatShortDate(DateTime dateTime) =>
      DateFormat('dd MMM yyyy').format(dateTime);

  /// e.g. "Monday, 03 August 2026"
  static String formatFullDate(DateTime dateTime) =>
      DateFormat('EEEE, dd MMMM yyyy').format(dateTime);

  /// e.g. "07:15 PM"
  static String formatTime(DateTime dateTime) =>
      DateFormat('hh:mm a').format(dateTime);

  /// e.g. "03 Aug 2026, 07:15 PM"
  static String formatDateTime(DateTime dateTime) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);

  /// Returns a relative description (e.g. "Today", "Yesterday", "2 days ago")
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (now.day == dateTime.day) {
        return 'Today';
      }
      return 'Yesterday';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatShortDate(dateTime);
    }
  }
}
