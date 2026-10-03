import 'package:flux_convert/core/error/failures.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_file.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentEvents — Sealed Union representing pipeline event updates
/// ─────────────────────────────────────────────────────────────────────────────
sealed class DocumentEvent {
  const DocumentEvent();
}

/// Fired when a document is selected by the user.
final class DocumentSelectedEvent extends DocumentEvent {
  const DocumentSelectedEvent(this.filePath);
  final String filePath;
}

/// Fired when document validators complete.
final class DocumentValidatedEvent extends DocumentEvent {
  const DocumentValidatedEvent(this.document);
  final DocumentFile document;
}

/// Fired when temporary directories and naming collisions are resolved.
final class DocumentPreparedEvent extends DocumentEvent {
  const DocumentPreparedEvent(this.outputPath);
  final String outputPath;
}

/// Fired when conversion processing begins.
final class DocumentStartedEvent extends DocumentEvent {
  const DocumentStartedEvent();
}

/// Fired periodically to notify numeric progress increments (0.0 to 1.0).
final class DocumentProgressEvent extends DocumentEvent {
  const DocumentProgressEvent(this.progress);
  final double progress;
}

/// Fired when the output file is successfully written.
final class DocumentCompletedEvent extends DocumentEvent {
  const DocumentCompletedEvent(this.response);
  final DocumentConversionResponse response;
}

/// Fired when the active task is cancelled by user trigger.
final class DocumentCancelledEvent extends DocumentEvent {
  const DocumentCancelledEvent();
}

/// Fired when an exception aborts the pipeline.
final class DocumentFailedEvent extends DocumentEvent {
  const DocumentFailedEvent(this.failure);
  final Failure failure;
}
