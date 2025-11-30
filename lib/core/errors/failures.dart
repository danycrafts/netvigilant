import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {
  final String message;
  
  const ServerFailure(this.message);
  
  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;
  
  const CacheFailure(this.message);
  
  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  final String message;
  
  const NetworkFailure(this.message);
  
  @override
  List<Object> get props => [message];
}

class PermissionFailure extends Failure {
  final String message;
  
  const PermissionFailure(this.message);
  
  @override
  List<Object> get props => [message];
}

class PlatformFailure extends Failure {
  final String message;
  
  const PlatformFailure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ValidationFailure extends Failure {
  final String message;
  
  const ValidationFailure(this.message);
  
  @override
  List<Object> get props => [message];
}

class DatabaseFailure extends Failure {
  final String message;
  
  const DatabaseFailure(this.message);
  
  @override
  List<Object> get props => [message];
}