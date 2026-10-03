import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';

class CleanCacheUseCase implements NoParamsUseCase<void> {
  const CleanCacheUseCase(this._repository);
  final StorageRepository _repository;

  @override
  Future<Result<void>> call() => _repository.cleanCache();
}
