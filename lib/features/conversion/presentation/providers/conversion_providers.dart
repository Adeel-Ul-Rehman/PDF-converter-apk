import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/features/conversion/core/engine/conversion_manager.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_task.dart';

import 'package:flux_convert/features/security/presentation/providers/security_providers.dart';

/// Provides a single persistent instance of [ConversionManager] across screen updates.
final conversionManagerProvider = Provider<ConversionManager>((ref) {
  final securityManager = ref.watch(securityManagerProvider);
  final manager = ConversionManager(securityManager: securityManager);
  ref.onDispose(manager.clearQueue);
  return manager;
});

/// State notifier that listens to the [ConversionQueue] changes
/// and exposes the current list of tasks to UI views.
class ConversionQueueNotifier extends StateNotifier<List<ConversionTask>> {
  ConversionQueueNotifier(this._manager) : super([]) {
    _manager.queue.addListener(_onQueueUpdated);
    _onQueueUpdated(); // Initial load
  }

  final ConversionManager _manager;

  void _onQueueUpdated() {
    state = _manager.queue.tasks;
  }

  @override
  void dispose() {
    _manager.queue.removeListener(_onQueueUpdated);
    super.dispose();
  }
}

/// Provides the reactive list of conversion tasks.
final conversionQueueProvider =
    StateNotifierProvider<ConversionQueueNotifier, List<ConversionTask>>((ref) {
  final manager = ref.watch(conversionManagerProvider);
  return ConversionQueueNotifier(manager);
});
