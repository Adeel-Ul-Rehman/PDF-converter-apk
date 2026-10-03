/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentMetadata
///
/// Immutable metadata containing properties of the source document file.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentMetadata {
  const DocumentMetadata({
    required this.fileName,
    required this.extension,
    required this.sizeBytes,
    required this.createdDate, required this.modifiedDate, this.pageCount,
    this.author,
  });

  /// File name with extension.
  final String fileName;

  /// Lowercase extension string (without dot).
  final String extension;

  /// File size in bytes.
  final int sizeBytes;

  /// Page count (for PDF, Word, PowerPoint files). Null if unparsed or unsupported.
  final int? pageCount;

  /// Creator author tag. Null if missing.
  final String? author;

  /// Timestamp of when the file was created.
  final DateTime createdDate;

  /// Timestamp of when the file was last modified.
  final DateTime modifiedDate;

  @override
  String toString() =>
      'DocumentMetadata($fileName): pages=$pageCount, size=$sizeBytes bytes';
}
