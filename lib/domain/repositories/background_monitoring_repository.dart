import 'package:dartz/dartz.dart';
import 'package:netvigilant/core/errors/failures.dart';

abstract class BackgroundMonitoringRepository {
  Future<Either<Failure, void>> startBackgroundMonitoring();
  Future<Either<Failure, void>> stopBackgroundMonitoring();
  Future<Either<Failure, bool>> isBackgroundMonitoringActive();
}