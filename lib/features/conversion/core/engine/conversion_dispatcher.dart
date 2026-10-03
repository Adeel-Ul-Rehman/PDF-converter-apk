import 'dart:async';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/core/converters/conversion_factory.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_enums.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_task.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_queue.dart';
import 'package:flux_convert/features/security/data/services/security_manager.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionDispatcher
///
/// Responsible for popping items off the queue and routing them to the correct
/// conversion engine. It handles lifecycles, cancellations, and logging.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionDispatcher {
  ConversionDispatcher(this._queue, this._securityManager);

  final ConversionQueue _queue;
  final SecurityManager _securityManager;
  bool _isDispatching = false;

  /// Polls the queue for the next pending task.
  void dispatchNext() {
    if (_isDispatching) return;
    final nextTask = _queue.tasks.where((t) => t.status == ConversionStatus.waiting).firstOrNull;

    if (nextTask != null) {
      _isDispatching = true;
      _runTask(nextTask).whenComplete(() {
        _isDispatching = false;
        dispatchNext();
      });
    }
  }

  Future<void> _runTask(ConversionTask task) async {
    AppLogger.info('Dispatcher: starting task ${task.id} (${task.inputExtension} -> ${task.outputExtension})');

    // ── 1. Update task to preparing ──────────────────────────────────────────
    var runningTask = task.copyWith(
      status: ConversionStatus.preparing,
      startedTime: DateTime.now(),
      progress: 0.05,
    );
    _queue.updateTask(runningTask);

    // ── 2. Run validations via SecurityManager ───────────────────────────────
    final validationResult = await _securityManager.authorizeAndValidateConversion(
      inputPath: runningTask.inputPath,
      targetExtension: runningTask.outputExtension,
    );
    
    if (validationResult.isFailure) {
      _finalizeTaskAsFailed(runningTask, validationResult.failure.message);
      return;
    }

    // Check for user cancellation during validation
    if (_isCancelled(runningTask.id)) return;

    // ── 3. Lookup factory converter ──────────────────────────────────────────
    runningTask = runningTask.copyWith(status: ConversionStatus.reading, progress: 0.15);
    _queue.updateTask(runningTask);

    final factoryResult = ConversionFactory.getConverter(
      runningTask.inputExtension,
      runningTask.outputExtension,
    );

    if (factoryResult.isFailure) {
      _finalizeTaskAsFailed(runningTask, factoryResult.failure.message);
      return;
    }

    final converter = factoryResult.value;

    // Check for user cancellation
    if (_isCancelled(runningTask.id)) return;

    // ── 4. Execute Converter ──────────────────────────────────────────────────
    runningTask = runningTask.copyWith(status: ConversionStatus.processing, progress: 0.25);
    _queue.updateTask(runningTask);

    final stopWatch = Stopwatch()..start();
    try {
      final conversionResult = await converter.convert(runningTask, (progressVal) {
        // Map 0.0-1.0 progress reporting from converter to 0.25-0.90 in dispatcher
        if (!_isCancelled(runningTask.id)) {
          final mappedProgress = 0.25 + (progressVal * 0.65);
          _queue.updateTask(
            runningTask.copyWith(
              status: ConversionStatus.processing,
              progress: mappedProgress,
            ),
          );
        }
      });

      stopWatch.stop();

      if (_isCancelled(runningTask.id)) return;

      if (conversionResult.isSuccess) {
        // ── 5. Finalize output and log success ────────────────────────────────
        final finalResult = conversionResult.value;
        _queue.updateTask(
          runningTask.copyWith(
            status: ConversionStatus.completed,
            progress: 1.0,
            finishedTime: DateTime.now(),
            duration: stopWatch.elapsed,
            outputPath: finalResult.destinationPath,
          ),
        );
        AppLogger.info('Dispatcher: task ${runningTask.id} completed in ${stopWatch.elapsedMilliseconds}ms.');
      } else {
        _finalizeTaskAsFailed(runningTask, conversionResult.failure.message);
      }
    } catch (e, stack) {
      stopWatch.stop();
      _finalizeTaskAsFailed(
        runningTask,
        'Conversion execution encountered an unhandled exception: $e',
        technicalMessage: e.toString(),
        stackTrace: stack,
      );
    } finally {
      _isDispatching = false;
      // Loop to next waiting task in queue
      dispatchNext();
    }
  }

  bool _isCancelled(String taskId) {
    // Check if task status has been updated to cancelled in the queue by user
    final currentTasks = _queue.tasks;
    final index = currentTasks.indexWhere((t) => t.id == taskId);
    if (index != -1 && currentTasks[index].status == ConversionStatus.cancelled) {
      AppLogger.info('Dispatcher: task $taskId was cancelled by user. Aborting.');
      _isDispatching = false;
      dispatchNext();
      return true;
    }
    return false;
  }

  void _finalizeTaskAsFailed(
    ConversionTask task,
    String message, {
    String? technicalMessage,
    StackTrace? stackTrace,
  }) {
    AppLogger.error('Dispatcher: task ${task.id} failed: $message', technicalMessage, stackTrace);
    
    _queue.updateTask(
      task.copyWith(
        status: ConversionStatus.failed,
        failure: message,
        finishedTime: DateTime.now(),
        progress: 0.0,
      ),
    );
    _isDispatching = false;
    dispatchNext();
  }
}
