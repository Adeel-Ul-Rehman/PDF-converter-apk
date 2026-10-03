// ─────────────────────────────────────────────────────────────────────────────
// Document Failures Exports
//
// Re-exports Clean Architecture failure subclasses for document feature modules.
// ─────────────────────────────────────────────────────────────────────────────
export 'package:flux_convert/core/error/failures.dart'
    show
        CorruptedDocumentFailure,
        EncryptedDocumentFailure,
        LargeDocumentFailure,
        MissingDocumentFailure,
        UnknownDocumentFailure,
        UnsupportedDocumentFailure;
