import 'package:flux_convert/core/error/exceptions.dart';
import 'package:flux_convert/core/error/failures.dart';
import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flux_convert/features/settings/data/models/settings_model.dart';
import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';
import 'package:flux_convert/features/settings/domain/repositories/settings_repository.dart';

/// Repository implementation that translates storage failures into domain failures.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<Result<SettingsEntity>> getSettings() async {
    try {
      final model = await _localDataSource.fetchSettings();
      return Success(model.toDomain());
    } on StorageException catch (error) {
      return FailureResult(StorageFailure.fromException(error));
    } on Object catch (error, stack) {
      return FailureResult(UnknownFailure.fromError(error, stack));
    }
  }

  @override
  Future<Result<void>> saveSettings(SettingsEntity settings) async {
    try {
      await _localDataSource.cacheSettings(SettingsModel.fromDomain(settings));
      return const Success(null);
    } on StorageException catch (error) {
      return FailureResult(StorageFailure.fromException(error));
    } on Object catch (error, stack) {
      return FailureResult(UnknownFailure.fromError(error, stack));
    }
  }

  @override
  Future<Result<void>> resetSettings() async {
    try {
      await _localDataSource.resetSettings();
      return const Success(null);
    } on StorageException catch (error) {
      return FailureResult(StorageFailure.fromException(error));
    } on Object catch (error, stack) {
      return FailureResult(UnknownFailure.fromError(error, stack));
    }
  }

  @override
  Future<Result<void>> updateSetting(String key, Object? value) async {
    try {
      await _localDataSource.updateSetting(key, value);
      return const Success(null);
    } on StorageException catch (error) {
      return FailureResult(StorageFailure.fromException(error));
    } on Object catch (error, stack) {
      return FailureResult(UnknownFailure.fromError(error, stack));
    }
  }

  @override
  Future<Result<void>> clearPreferences() async {
    try {
      await _localDataSource.clearPreferences();
      return const Success(null);
    } on StorageException catch (error) {
      return FailureResult(StorageFailure.fromException(error));
    } on Object catch (error, stack) {
      return FailureResult(UnknownFailure.fromError(error, stack));
    }
  }
}
