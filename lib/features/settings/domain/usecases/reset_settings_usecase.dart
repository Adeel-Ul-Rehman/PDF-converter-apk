import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/settings/domain/repositories/settings_repository.dart';

/// Reset use case for restoring the canonical default settings.
class ResetSettingsUseCase implements NoParamsUseCase<void> {
  ResetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<void>> call() => _repository.resetSettings();
}
