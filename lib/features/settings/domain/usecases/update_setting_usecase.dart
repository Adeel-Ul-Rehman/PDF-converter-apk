import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/settings/domain/repositories/settings_repository.dart';

/// Use case for updating a single setting value.
class UpdateSettingUseCase implements UseCase<void, UpdateSettingParams> {
  UpdateSettingUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<void>> call(UpdateSettingParams params) =>
      _repository.updateSetting(params.key, params.value);
}

class UpdateSettingParams {
  const UpdateSettingParams({required this.key, required this.value});

  final String key;
  final Object? value;
}
