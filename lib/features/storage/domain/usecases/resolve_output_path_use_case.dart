import 'package:equatable/equatable.dart';
import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';

class ResolveOutputPathParams extends Equatable {
  const ResolveOutputPathParams({
    required this.baseName,
    required this.extension,
  });
  final String baseName;
  final String extension;

  @override
  List<Object?> get props => [baseName, extension];
}

class ResolveOutputPathUseCase
    implements UseCase<String, ResolveOutputPathParams> {
  const ResolveOutputPathUseCase(this._repository);
  final StorageRepository _repository;

  @override
  Future<Result<String>> call(ResolveOutputPathParams params) =>
      _repository.resolveOutputPath(
        baseName: params.baseName,
        extension: params.extension,
      );
}
