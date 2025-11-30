import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:netvigilant/core/errors/failures.dart';
import 'package:netvigilant/core/usecases/usecase.dart';
import 'package:netvigilant/domain/entities/app_usage_entity.dart';
import 'package:netvigilant/domain/repositories/network_repository.dart';

class GetAppUsage implements UseCase<List<AppUsageEntity>, GetAppUsageParams> {
  final AbstractNetworkRepository repository;

  GetAppUsage(this.repository);

  @override
  Future<Either<Failure, List<AppUsageEntity>>> call(GetAppUsageParams params) async {
    try {
      final result = await repository.getAppUsage(
        start: params.start,
        end: params.end,
      );
      return Right(result);
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }
}

class GetAppUsageParams extends Equatable {
  final DateTime start;
  final DateTime end;

  const GetAppUsageParams({
    required this.start,
    required this.end,
  });

  @override
  List<Object> get props => [start, end];
}