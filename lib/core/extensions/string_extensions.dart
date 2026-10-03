/// ─────────────────────────────────────────────────────────────────────────────
/// String Extensions
/// ─────────────────────────────────────────────────────────────────────────────
extension StringX on String {
  /// Returns `null` if the string is empty, otherwise returns the string.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Returns `true` if the string is not empty and not whitespace-only.
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns `true` if the string is empty or whitespace-only.
  bool get isBlank => trim().isEmpty;

  /// Capitalises the first character of the string.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Converts a snake_case or camelCase string to Title Case.
  String get toTitleCase => split(RegExp(r'[_\s]+'))
      .map((w) => w.capitalised)
      .join(' ');

  /// Returns the file extension from a file path (e.g. `'pdf'` from `'file.pdf'`).
  String get fileExtension {
    final idx = lastIndexOf('.');
    return idx == -1 ? '' : substring(idx + 1).toLowerCase();
  }

  /// Returns the file name without extension.
  String get fileNameWithoutExtension {
    final name = split(RegExp(r'[/\\]')).last;
    final idx = name.lastIndexOf('.');
    return idx == -1 ? name : name.substring(0, idx);
  }

  /// Returns a truncated string with an ellipsis if longer than [maxLength].
  String truncate(int maxLength, {String ellipsis = '…'}) =>
      length <= maxLength ? this : '${substring(0, maxLength)}$ellipsis';
}
