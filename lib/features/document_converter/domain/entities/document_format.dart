/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentFormat
///
/// Enum mapping document format extensions and conversion matrix pathways.
/// ─────────────────────────────────────────────────────────────────────────────
enum DocumentFormat {
  pdf,
  doc,
  docx,
  txt,
  rtf,
  html,
  odt;

  /// Returns the standard file extension name.
  String get extension => name;

  /// Returns user-friendly name.
  String get displayName => switch (this) {
        DocumentFormat.pdf => 'PDF Document',
        DocumentFormat.doc => 'Word 97-2003 Document',
        DocumentFormat.docx => 'Word Document',
        DocumentFormat.txt => 'Plain Text',
        DocumentFormat.rtf => 'Rich Text Format',
        DocumentFormat.html => 'HTML Webpage',
        DocumentFormat.odt => 'OpenDocument Text',
      };

  /// Parses file extension to [DocumentFormat]. Returns null if unsupported.
  static DocumentFormat? fromExtension(String ext) {
    final cleanExt = ext.toLowerCase().replaceAll('.', '').trim();
    for (final val in values) {
      if (val.extension == cleanExt) return val;
    }
    return null;
  }

  /// Centralized mapping matrix detailing possible output paths.
  /// UI queries this matrix to show format chips dynamically.
  static List<DocumentFormat> getSupportedOutputs(DocumentFormat input) => switch (input) {
      DocumentFormat.pdf => const [
          DocumentFormat.docx,
          DocumentFormat.txt,
          DocumentFormat.html,
        ],
      DocumentFormat.doc => const [
          DocumentFormat.pdf,
          DocumentFormat.docx,
        ],
      DocumentFormat.docx => const [
          DocumentFormat.pdf,
          DocumentFormat.txt,
        ],
      DocumentFormat.txt => const [
          DocumentFormat.pdf,
          DocumentFormat.docx,
        ],
      DocumentFormat.rtf => const [
          DocumentFormat.pdf,
        ],
      DocumentFormat.html => const [
          DocumentFormat.pdf,
        ],
      DocumentFormat.odt => const [
          DocumentFormat.pdf,
        ],
    };

  /// Returns true if a specific pathway is supported by the matrix.
  static bool canConvert(DocumentFormat input, DocumentFormat output) => getSupportedOutputs(input).contains(output);
}
/// Centralized mapping matrix query helper.
abstract final class DocumentConversionMatrix {
  static List<String> getSupportedOutputs(String extension) {
    final format = DocumentFormat.fromExtension(extension);
    if (format == null) return const [];
    return DocumentFormat.getSupportedOutputs(format)
        .map((f) => f.extension)
        .toList();
  }
}
