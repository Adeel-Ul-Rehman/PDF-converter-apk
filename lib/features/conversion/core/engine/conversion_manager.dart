import 'package:uuid/uuid.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_enums.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_task.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_dispatcher.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_queue.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_storage_manager.dart';

import 'package:flux_convert/features/security/data/services/security_manager.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionManager
///
/// Facade coordinator wrapping dispatcher schedulers and queue registries.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionManager {
  ConversionManager({required SecurityManager securityManager}) {
    _dispatcher = ConversionDispatcher(_queue, securityManager);
    
    // Listen to queue changes to auto-start idle dispatcher
    _queue.addListener(() {
      _dispatcher.dispatchNext();
    });
  }

  final ConversionQueue _queue = ConversionQueue();
  late final ConversionDispatcher _dispatcher;
  final _uuid = const Uuid();

  /// Gets the queue task scheduler.
  ConversionQueue get queue => _queue;

  /// Gets the dispatcher coordinator.
  ConversionDispatcher get dispatcher => _dispatcher;

  /// Creates and schedules a new conversion task in the queue.
  Future<Result<String>> requestConversion({
    required String inputPath,
    required String targetExtension,
  }) async {
    try {
      final sourceName = inputPath.split('/').last.split(r'\').last;
      final baseName = sourceName.contains('.')
          ? sourceName.substring(0, sourceName.lastIndexOf('.'))
          : sourceName;
      final sourceExt = sourceName.contains('.')
          ? sourceName.substring(sourceName.lastIndexOf('.') + 1).toLowerCase()
          : '';

      final targetExt = targetExtension.trim().toLowerCase().replaceAll('.', '');

      // ── 1. Allocate output storage path ────────────────────────────────────
      final destPathResult = await ConversionStorageManager.getDestinationPath(
        baseName,
        targetExt,
      );

      if (destPathResult.isFailure) {
        return FailureResult(destPathResult.failure);
      }

      final destPath = destPathResult.value;
      final taskId = _uuid.v4();

      // ── 2. Create task parameters ──────────────────────────────────────────
      final task = ConversionTask(
        id: taskId,
        inputPath: inputPath,
        outputPath: destPath,
        inputExtension: sourceExt,
        outputExtension: targetExt,
        status: ConversionStatus.waiting,
        progress: 0.0,
        createdTime: DateTime.now(),
      );

      // ── 3. Queue task ──────────────────────────────────────────────────────
      _queue.enqueue(task);
      AppLogger.info('Manager: Queued conversion task $taskId ($sourceExt -> $targetExt)');

      return Success(taskId);
    } catch (e, stack) {
      return FailureResult(
        UnknownFailure(
          message: 'Failed to queue conversion task.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  /// Cancels a running or pending conversion task.
  void cancelTask(String taskId) {
    _queue.cancel(taskId);
    AppLogger.info('Manager: Cancelled conversion task $taskId');
  }

  /// Retries a failed or cancelled conversion task.
  void retryTask(String taskId) {
    _queue.retry(taskId);
    AppLogger.info('Manager: Retrying conversion task $taskId');
  }

  /// Clears the scheduler queue list.
  void clearQueue() {
    _queue.clear();
    AppLogger.info('Manager: Cleared conversion queue');
  }
}
