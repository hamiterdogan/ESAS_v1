// Base result class for API responses
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String message, {int? statusCode, String? errorCode}) = Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
    R Function()? loading,
  }) {
    return switch (this) {
      Success<T> s => success(s.data),
      Failure<T> f => failure(f.message),
      Loading<T> _ => loading != null ? loading() : throw Exception('Loading state not handled'),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const Failure(this.message, {this.statusCode, this.errorCode});
}

class Loading<T> extends Result<T> {
  const Loading();
}
