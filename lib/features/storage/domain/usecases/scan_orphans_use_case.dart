import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';

class ScanOrphansUseCase implements NoParamsUseCase<List<String>> {
  const ScanOrphansUseCase(this._repository);
  final StorageRepository _repository;

  @override
  Future<Result<List<String>>> call() =>
      _repository.scanOrphanTempFiles();
}
