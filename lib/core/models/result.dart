// Base result class for API responses
sealed class Result<T> {
  const Result();
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
