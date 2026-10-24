/// Errors the UI knows how to display.
///
/// The data layer converts every low-level exception (network, HTTP status,
/// JSON parsing) into one of these types, so screens never show raw
/// exceptions or stack traces. Because the class is `sealed`, a `switch`
/// over an [AppFailure] must handle every subtype or it won't compile.
sealed class AppFailure implements Exception {
  const AppFailure();

  /// A short, user-facing explanation.
  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connection, DNS failure or the server refused the connection.
final class NetworkFailure extends AppFailure {
  const NetworkFailure();

  @override
  String get message =>
      'You appear to be offline. Check your connection and try again.';
}

/// Our server, or the data provider behind it, took too long to respond.
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();

  @override
  String get message =>
      'The server took too long to respond. Please try again.';
}

/// Too many requests were made in a short time.
final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({this.retryAfter});

  /// How long to wait before retrying, when the server says so.
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

/// The requested coin does not exist.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();

  @override
  String get message => 'This coin could not be found.';
}

/// Any other server error, including responses we could not understand.
final class ServerFailure extends AppFailure {
  const ServerFailure({this.code});

  /// The backend's error code (e.g. `UPSTREAM_ERROR`), kept for logging.
  final String? code;

  @override
  String get message =>
      'Something went wrong on our side. Please try again later.';
}
