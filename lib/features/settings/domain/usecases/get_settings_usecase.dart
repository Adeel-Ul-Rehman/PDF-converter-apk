import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';
import 'package:flux_convert/features/settings/domain/repositories/settings_repository.dart';

/// Get the persisted settings entity.
class GetSettingsUseCase implements NoParamsUseCase<SettingsEntity> {
  GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<SettingsEntity>> call() => _repository.getSettings();
}
