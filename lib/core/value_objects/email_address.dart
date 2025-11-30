import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:netvigilant/core/errors/failures.dart';

class EmailAddress extends Equatable {
  final String value;

  const EmailAddress._(this.value);

  static Either<Failure, EmailAddress> create(String input) {
    if (input.isEmpty) {
      return Left(ValidationFailure('Email cannot be empty'));
    }
    // A simple regex for email validation
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(input)) {
      return Left(ValidationFailure('Invalid email format'));
    }
    return Right(EmailAddress._(input));
  }

  @override
  List<Object> get props => [value];

  @override
  bool get stringify => true;
}