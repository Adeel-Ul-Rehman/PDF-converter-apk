import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';

class ClearHistoryUseCase implements NoParamsUseCase<void> {
  ClearHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Result<void>> call() => _repository.clearAll();
}
