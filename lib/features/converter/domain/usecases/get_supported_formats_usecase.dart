import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/domain/repositories/converter_repository.dart';

/// Use case to fetch all formats that the app's converter currently supports.
class GetSupportedFormatsUseCase implements NoParamsUseCase<List<ConversionFormat>> {
  GetSupportedFormatsUseCase(this._repository);

  final ConverterRepository _repository;

  @override
  Future<Result<List<ConversionFormat>>> call() => _repository.getSupportedFormats();
}
