import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flux_convert/features/history/data/models/history_record_model.dart';
import 'package:flux_convert/features/history/data/models/conversion_history_model.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// HistoryLocalDataSource — Local Key-Value Store for History
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class HistoryLocalDataSource {
  // Legacy compatibility methods
  Future<List<HistoryRecordModel>> fetchRecords();
  Future<void> saveRecord(HistoryRecordModel record);
  Future<void> clearAll();

  // Rich history methods
  Future<List<ConversionHistoryModel>> fetchHistory();
  Future<void> saveHistoryItem(ConversionHistoryModel item);
  Future<void> saveHistoryList(List<ConversionHistoryModel> list);
  Future<void> deleteHistoryItem(String id);
  Future<void> clearRichHistory();
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  HistoryLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;
  static const _historyKey = 'fc_conversion_history';
  static const _richHistoryKey = 'fc_rich_conversion_history';

  // ── Legacy Methods implementation ──────────────────────────────────────────
  @override
  Future<List<HistoryRecordModel>> fetchRecords() async {
    final rawList = _prefs.getStringList(_historyKey);
    if (rawList == null) return [];
    return rawList
        .map((s) => HistoryRecordModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveRecord(HistoryRecordModel record) async {
    final list = await fetchRecords();
    list.insert(0, record);
    final serialized = list.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_historyKey, serialized);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_historyKey);
  }

  // ── Rich History Methods implementation ─────────────────────────────────────
  @override
  Future<List<ConversionHistoryModel>> fetchHistory() async {
    final rawList = _prefs.getStringList(_richHistoryKey);
    if (rawList == null) return [];
    return rawList
        .map((s) => ConversionHistoryModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveHistoryItem(ConversionHistoryModel item) async {
    final list = await fetchHistory();
    list.insert(0, item); // Newest first
    await saveHistoryList(list);
  }

  @override
  Future<void> saveHistoryList(List<ConversionHistoryModel> list) async {
    final serialized = list.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_richHistoryKey, serialized);
  }

  @override
  Future<void> deleteHistoryItem(String id) async {
    final list = await fetchHistory();
    list.removeWhere((item) => item.id == id);
    await saveHistoryList(list);
  }

  @override
  Future<void> clearRichHistory() async {
    await _prefs.remove(_richHistoryKey);
  }
}
