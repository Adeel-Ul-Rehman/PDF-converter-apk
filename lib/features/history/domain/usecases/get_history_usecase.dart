import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/history/domain/entities/history_record.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';

class GetHistoryUseCase implements NoParamsUseCase<List<HistoryRecord>> {
  GetHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Result<List<HistoryRecord>>> call() => _repository.getAllRecords();
}
