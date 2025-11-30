import 'package:dartz/dartz.dart';
import 'package:netvigilant/core/errors/failures.dart';
import 'package:netvigilant/core/usecases/usecase.dart';
import 'package:netvigilant/domain/repositories/background_monitoring_repository.dart';
import 'package:netvigilant/domain/repositories/network_repository.dart';

class StartContinuousMonitoring implements UseCase<void, NoParams> {
  final AbstractNetworkRepository repository;

  StartContinuousMonitoring(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await repository.startContinuousMonitoring();
      return const Right(null);
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }
}

class StopContinuousMonitoring implements UseCase<void, NoParams> {
  final AbstractNetworkRepository repository;

  StopContinuousMonitoring(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await repository.stopContinuousMonitoring();
      return const Right(null);
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }
}

class StartBackgroundMonitoring implements UseCase<void, NoParams> {
  final BackgroundMonitoringRepository _repository;

  StartBackgroundMonitoring(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _repository.startBackgroundMonitoring();
  }
}

class StopBackgroundMonitoring implements UseCase<void, NoParams> {
  final BackgroundMonitoringRepository _repository;

  StopBackgroundMonitoring(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await _repository.stopBackgroundMonitoring();
  }
}

class CheckBackgroundMonitoringStatus implements UseCase<bool, NoParams> {
  final BackgroundMonitoringRepository _repository;

  CheckBackgroundMonitoringStatus(this._repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await _repository.isBackgroundMonitoringActive();
  }
}