import 'package:flux_convert/core/error/failures.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentValidation
///
/// Report detailing the validation checks performed on a document.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentValidation {
  const DocumentValidation({
    required this.isValid,
    required this.failures,
  });

  /// True if all validators passed cleanly.
  final bool isValid;

  /// Lists of specific validation failures.
  final List<Failure> failures;

  /// Helper returning the first failure message if exists.
  String? get firstErrorMessage => failures.isEmpty ? null : failures.first.message;
}
