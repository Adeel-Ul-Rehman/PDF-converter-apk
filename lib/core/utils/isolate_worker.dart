import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// IsolateWorker
///
/// IMPROVED: Thin typed wrapper around Flutter's compute() function.
/// Offloads CPU-bound tasks to a background isolate, keeping the UI thread
/// free for 60fps rendering.
///
/// Usage:
///   final result = await IsolateWorker.run(_myTopLevelFn, myMessage);
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class IsolateWorker {
  /// Runs [callback] in a background isolate with [message] as the argument.
  ///
  /// [callback] MUST be a top-level function — no closures, no instance methods.
  static Future<R> run<R, M>(
    ComputeCallback<M, R> callback,
    M message,
  ) =>
      compute(callback, message);
}
