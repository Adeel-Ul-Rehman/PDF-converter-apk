import 'package:flux_convert/features/conversion/domain/entities/conversion_enums.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_task.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionQueue
///
/// FIFO job queue scheduler, supporting cancellation, retrying, and clearing.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionQueue {
  final List<ConversionTask> _tasks = [];
  final List<void Function()> _listeners = [];

  /// Returns the current list of tasks in the queue.
  List<ConversionTask> get tasks => List.unmodifiable(_tasks);

  /// Registers state changes listeners.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Deregisters state changes listeners.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Appends a new job task to the end of the queue.
  void enqueue(ConversionTask task) {
    _tasks.add(task);
    _notifyListeners();
  }

  /// Retrieves and pops the next waiting task (FIFO).
  ConversionTask? dequeue() {
    try {
      final index = _tasks.indexWhere((t) => t.status == ConversionStatus.waiting);
      if (index != -1) {
        return _tasks[index];
      }
    } catch (_) {}
    return null;
  }

  /// Cancels a pending or active task in the queue.
  void cancel(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      if (!task.status.isTerminal) {
        _tasks[index] = task.copyWith(
          status: ConversionStatus.cancelled,
          finishedTime: DateTime.now(),
        );
        _notifyListeners();
      }
    }
  }

  /// Retries a failed or cancelled task by placing it back in waiting status.
  void retry(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        status: ConversionStatus.waiting,
        progress: 0.0,
      );
      _notifyListeners();
    }
  }

  /// Clears all tasks from the queue list.
  void clear() {
    _tasks.clear();
    _notifyListeners();
  }

  /// Updates a specific task's values (such as progress or status changes).
  void updateTask(ConversionTask updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _notifyListeners();
    }
  }
}
