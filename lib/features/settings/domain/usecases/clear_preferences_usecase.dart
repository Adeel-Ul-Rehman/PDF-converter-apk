import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/settings/domain/repositories/settings_repository.dart';

/// Use case to clear all saved preferences.
class ClearPreferencesUseCase implements NoParamsUseCase<void> {
  ClearPreferencesUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<void>> call() => _repository.clearPreferences();
}
