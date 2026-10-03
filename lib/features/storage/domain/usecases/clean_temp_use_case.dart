import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';

class CleanTempUseCase implements NoParamsUseCase<void> {
  const CleanTempUseCase(this._repository);
  final StorageRepository _repository;

  @override
  Future<Result<void>> call() => _repository.cleanTemp();
}
