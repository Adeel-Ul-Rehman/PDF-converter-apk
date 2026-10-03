import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PerformanceLogger — Debug‑only logger that stores simple metrics in memory.
/// In release builds all methods become no‑ops to avoid overhead.
/// ─────────────────────────────────────────────────────────────────────────────
class PerformanceLogger {
  final List<Map<String, dynamic>> _records = [];

  /// Records a key/value pair. In debug mode we keep it; in release we ignore.
  Future<void> record(String key, dynamic value) async {
    if (kDebugMode) {
      _records.add({'key': key, 'value': value, 'timestamp': DateTime.now()});
    }
  }

  /// Clears all stored records.
  Future<void> clearAll() async {
    if (kDebugMode) {
      _records.clear();
    }
  }

  /// Returns a copy of the log – useful for dev tools.
  List<Map<String, dynamic>> get logs => List.unmodifiable(_records);
}
