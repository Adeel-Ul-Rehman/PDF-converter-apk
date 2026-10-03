import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';
import 'package:flux_convert/features/settings/domain/repositories/settings_repository.dart';

/// Save the full settings entity.
class SaveSettingsUseCase implements UseCase<void, SettingsEntity> {
  SaveSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<void>> call(SettingsEntity params) =>
      _repository.saveSettings(params);
}
