import 'package:dartz/dartz.dart';
import 'package:netvigilant/core/errors/failures.dart';
import 'package:netvigilant/core/usecases/usecase.dart';
import 'package:netvigilant/domain/entities/real_time_metrics_entity.dart';
import 'package:netvigilant/domain/repositories/network_repository.dart';

class GetRealTimeMetrics implements StreamUseCase<RealTimeMetricsEntity, NoParams> {
  final AbstractNetworkRepository repository;

  GetRealTimeMetrics(this.repository);

  @override
  Stream<Either<Failure, RealTimeMetricsEntity>> call(NoParams params) {
    try {
      return repository.getLiveTrafficStream().map((metrics) => Right(metrics));
    } catch (e) {
      return Stream.value(Left(PlatformFailure(e.toString())));
    }
  }
}