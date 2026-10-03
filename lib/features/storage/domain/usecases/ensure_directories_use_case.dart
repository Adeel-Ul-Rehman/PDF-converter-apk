import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_path_config.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';

class EnsureDirectoriesUseCase
    implements NoParamsUseCase<StoragePathConfig> {
  const EnsureDirectoriesUseCase(this._repository);
  final StorageRepository _repository;

  @override
  Future<Result<StoragePathConfig>> call() =>
      _repository.ensureDirectories();
}
