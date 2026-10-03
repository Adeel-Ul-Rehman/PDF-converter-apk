import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_statistics.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';

class GetStorageStatisticsUseCase
    implements NoParamsUseCase<StorageStatistics> {
  const GetStorageStatisticsUseCase(this._repository);
  final StorageRepository _repository;

  @override
  Future<Result<StorageStatistics>> call() =>
      _repository.getStatistics();
}
