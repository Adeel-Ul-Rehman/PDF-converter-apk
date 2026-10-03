// ─────────────────────────────────────────────────────────────────────────────
// Conversion Failures Exports
//
// Re-exports clean architecture failure types so they are correctly referenced
// under features/conversion feature modules.
// ─────────────────────────────────────────────────────────────────────────────
export 'package:flux_convert/core/error/failures.dart'
    show
        ConversionError,
        OutputError,
        QueueError,
        StorageError,
        UnknownConversionError,
        ValidationError;
