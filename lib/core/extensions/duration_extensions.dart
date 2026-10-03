/// ─────────────────────────────────────────────────────────────────────────────
/// DurationExtensions — Output formattings for Duration objects
/// ─────────────────────────────────────────────────────────────────────────────
extension DurationExtensions on Duration {
  /// Formats a duration to mm:ss format (e.g. "03:45").
  String toMinutesSeconds() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Formats to human readable string (e.g. "1m 30s", "45s", "2h 15m").
  String toHumanReadable() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
