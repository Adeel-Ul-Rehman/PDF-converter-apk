import 'dart:async';
import 'dart:isolate';

/// ─────────────────────────────────────────────────────────────────────────────
/// IsolateManager — Simple wrapper to run heavy functions in a background isolate.
///
/// Example usage:
///   final result = await IsolateManager.runInIsolate`<String>`(
///     (sendPort) async {
///       // heavy work here
///       final data = await computeHeavyTask();
///       sendPort.send(data);
///     },
///   );
/// ─────────────────────────────────────────────────────────────────────────────
class IsolateManager {
  /// Runs the provided [entryPoint] function in a new isolate and returns the
  /// result sent back through the [SendPort]. The generic type [T] is inferred
  /// from the message type.
  static Future<T> runInIsolate<T>(
    void Function(SendPort) entryPoint,
  ) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(entryPoint, receivePort.sendPort);
    final completer = Completer<T>();
    receivePort.listen((message) {
      if (message is T) {
        completer.complete(message);
      } else {
        // If the isolate sends an unexpected type, complete with an error.
        completer.completeError('Isolate returned unexpected type: ${message.runtimeType}');
      }
      receivePort.close();
    });
    return completer.future;
  }
}
