import 'dart:async';

/// ─────────────────────────────────────────────────────────────────────────────
/// PdfProgressTracker
///
/// Multi-task progress listener registration manager.
/// ─────────────────────────────────────────────────────────────────────────────
class PdfProgressTracker {
  final Map<String, void Function(double progress)> _callbacks = {};
  final Map<String, StreamController<double>> _controllers = {};

  /// Registers a task ID with its respective progress callback.
  void register(String taskId, void Function(double progress) onProgress) {
    _callbacks[taskId] = onProgress;
    final controller = StreamController<double>.broadcast();
    _controllers[taskId] = controller;
    controller.stream.listen(onProgress);
  }

  /// Sends a progress increment event (0.0 to 1.0) to the listener.
  void updateProgress(String taskId, double progress) {
    final callback = _callbacks[taskId];
    if (callback != null) {
      callback(progress);
    }
    final controller = _controllers[taskId];
    if (controller != null && !controller.isClosed) {
      controller.add(progress);
    }
  }

  /// Returns progress stream for a specific task.
  Stream<double>? getProgressStream(String taskId) => _controllers[taskId]?.stream;

  /// Unregisters and closes resources for a finished task.
  void remove(String taskId) {
    _callbacks.remove(taskId);
    final controller = _controllers.remove(taskId);
    controller?.close();
  }

  /// Clears all listeners.
  void clear() {
    _callbacks.clear();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
