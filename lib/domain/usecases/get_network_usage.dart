import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:netvigilant/core/errors/failures.dart';
import 'package:netvigilant/core/usecases/usecase.dart';
import 'package:netvigilant/domain/entities/network_traffic_entity.dart';
import 'package:netvigilant/domain/repositories/network_repository.dart';

class GetNetworkUsage implements UseCase<List<NetworkTrafficEntity>, GetNetworkUsageParams> {
  final AbstractNetworkRepository repository;

  GetNetworkUsage(this.repository);

  @override
  Future<Either<Failure, List<NetworkTrafficEntity>>> call(GetNetworkUsageParams params) async {
    try {
      final result = await repository.getNetworkUsage(
        start: params.start,
        end: params.end,
      );
      return Right(result);
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }
}

class GetNetworkUsageParams extends Equatable {
  final DateTime start;
  final DateTime end;

  const GetNetworkUsageParams({
    required this.start,
    required this.end,
  });

  @override
  List<Object> get props => [start, end];
}