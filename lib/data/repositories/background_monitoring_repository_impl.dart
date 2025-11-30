import 'package:dartz/dartz.dart';
import 'package:netvigilant/core/errors/failures.dart';
import 'package:netvigilant/data/datasources/background_monitoring_datasource.dart';
import 'package:netvigilant/domain/repositories/background_monitoring_repository.dart';

class BackgroundMonitoringRepositoryImpl implements BackgroundMonitoringRepository {
  final BackgroundMonitoringDataSource _dataSource;

  BackgroundMonitoringRepositoryImpl({
    required BackgroundMonitoringDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<Either<Failure, void>> startBackgroundMonitoring() async {
    try {
      await _dataSource.startBackgroundTask();
      return const Right(null);
    } catch (e) {
      return Left(PlatformFailure('Failed to start background monitoring: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> stopBackgroundMonitoring() async {
    try {
      await _dataSource.stopBackgroundTask();
      return const Right(null);
    } catch (e) {
      return Left(PlatformFailure('Failed to stop background monitoring: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isBackgroundMonitoringActive() async {
    try {
      final result = await _dataSource.isBackgroundTaskActive();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Failed to check monitoring status: ${e.toString()}'));
    }
  }
}