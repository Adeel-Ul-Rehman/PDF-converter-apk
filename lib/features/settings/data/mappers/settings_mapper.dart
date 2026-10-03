import 'package:flux_convert/features/settings/data/models/settings_model.dart';
import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SettingsMapper — Mapper between persistence model and domain entity.
///
/// Keeps the data layer decoupled from the domain layer. The mapper converts
/// [SettingsModel] (persistence representation) to [SettingsEntity] (domain
/// representation) and vice-versa.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class SettingsMapper {
  /// Converts a [SettingsModel] into a [SettingsEntity].
  static SettingsEntity toEntity(SettingsModel model) => model.toDomain();

  /// Converts a [SettingsEntity] into a [SettingsModel].
  static SettingsModel toModel(SettingsEntity entity) =>
      SettingsModel.fromDomain(entity);

  /// Maps a JSON map into a [SettingsEntity] using the persistence model.
  static SettingsEntity fromJson(Map<String, dynamic> json) =>
      SettingsModel.fromJson(json).toDomain();
}
