sealed class AppFailure implements Exception {
  const AppFailure();

  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();

  @override
  String get message =>
      'You appear to be offline. Check your connection and try again.';
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();

  @override
  String get message =>
      'The server took too long to respond. Please try again.';
}

final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({this.retryAfter});

  final Duration? retryAfter;

  @override
  String get message {
    final seconds = retryAfter?.inSeconds;
    if (seconds == null || seconds <= 0) {
      return 'Too many requests. Please try again shortly.';
    }
    return 'Too many requests. Please try again in $seconds seconds.';
  }
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();

  @override
  String get message => 'This coin could not be found.';
}

final class ServerFailure extends AppFailure {
  const ServerFailure({this.code});

  final String? code;

  @override
  String get message =>
      'Something went wrong on our side. Please try again later.';
}
