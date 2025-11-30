import 'package:dartz/dartz.dart';
import 'package:netvigilant/core/errors/failures.dart';
import 'package:netvigilant/core/usecases/usecase.dart';
import 'package:netvigilant/domain/repositories/network_repository.dart';

class CheckUsageStatsPermission implements UseCase<bool, NoParams> {
  final AbstractNetworkRepository repository;

  CheckUsageStatsPermission(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final result = await repository.hasUsageStatsPermission();
      return Right(result ?? false);
    } catch (e) {
      return Left(PermissionFailure(e.toString()));
    }
  }
}

class RequestUsageStatsPermission implements UseCase<void, NoParams> {
  final AbstractNetworkRepository repository;

  RequestUsageStatsPermission(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await repository.requestUsageStatsPermission();
      return const Right(null);
    } catch (e) {
      return Left(PermissionFailure(e.toString()));
    }
  }
}

class OpenBatteryOptimizationSettings implements UseCase<void, NoParams> {
  final AbstractNetworkRepository repository;

  OpenBatteryOptimizationSettings(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await repository.openBatteryOptimizationSettings();
      return const Right(null);
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }
}