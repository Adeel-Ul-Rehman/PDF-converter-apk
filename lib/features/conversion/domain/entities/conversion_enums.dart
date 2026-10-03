/// ─────────────────────────────────────────────────────────────────────────────
/// Conversion Enums
///
/// Standard types representing file conversion categories and statuses.
/// ─────────────────────────────────────────────────────────────────────────────
library;

/// Represents the broad category of conversion being executed.
enum ConversionCategory {
  document,
  image,
  spreadsheet,
  presentation,
  audio,
  video;

  String get displayName => switch (this) {
        ConversionCategory.document => 'Document',
        ConversionCategory.image => 'Image',
        ConversionCategory.spreadsheet => 'Spreadsheet',
        ConversionCategory.presentation => 'Presentation',
        ConversionCategory.audio => 'Audio',
        ConversionCategory.video => 'Video',
      };
}

/// Represents the operational status of a conversion task in the pipeline.
enum ConversionStatus {
  idle,
  waiting,
  preparing,
  reading,
  processing,
  writing,
  completed,
  cancelled,
  failed;

  bool get isTerminal =>
      this == ConversionStatus.completed ||
      this == ConversionStatus.cancelled ||
      this == ConversionStatus.failed;

  bool get isRunning =>
      this == ConversionStatus.preparing ||
      this == ConversionStatus.reading ||
      this == ConversionStatus.processing ||
      this == ConversionStatus.writing;

  String get displayName => switch (this) {
        ConversionStatus.idle => 'Idle',
        ConversionStatus.waiting => 'Waiting in queue',
        ConversionStatus.preparing => 'Preparing file...',
        ConversionStatus.reading => 'Reading contents...',
        ConversionStatus.processing => 'Processing conversion...',
        ConversionStatus.writing => 'Writing destination output...',
        ConversionStatus.completed => 'Completed',
        ConversionStatus.cancelled => 'Cancelled',
        ConversionStatus.failed => 'Failed',
      };
}
