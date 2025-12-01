abstract class Result<T> {
  const Result();
  
  factory Result.success(T data) = Success<T>;
  factory Result.failure(String error) = Failure<T>;
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  
  T? get data => isSuccess ? (this as Success<T>).data : null;
  String? get error => isFailure ? (this as Failure<T>).error : null;
  
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String error) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as Failure<T>).error);
    }
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success && runtimeType == other.runtimeType && data == other.data;
  
  @override
  int get hashCode => data.hashCode;
  
  @override
  String toString() => 'Success(data: $data)';
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure && runtimeType == other.runtimeType && error == other.error;
  
  @override
  int get hashCode => error.hashCode;
  
  @override
  String toString() => 'Failure(error: $error)';
}