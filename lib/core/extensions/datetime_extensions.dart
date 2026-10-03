/// ─────────────────────────────────────────────────────────────────────────────
/// DateTime Extensions
/// ─────────────────────────────────────────────────────────────────────────────
extension DateTimeX on DateTime {
  /// Returns `true` if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns `true` if this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Formats the date as a human-readable relative string
  /// (e.g. "Today", "Yesterday", or "Aug 2, 2026").
  String get relativeLabel {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return '$day ${_monthAbbr(month)} $year';
  }

  /// Returns a short time string (e.g. "14:30").
  String get shortTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String _monthAbbr(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];
}
