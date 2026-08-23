import 'package:dio/dio.dart';

/// A failure the UI can actually say something useful about.
class ApiException implements Exception {
  const ApiException(this.message, {this.isRetryable = true});

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is! DioException) {
      return const ApiException("Something went wrong. That's on us.");
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException(
        'TMDB took too long to answer. Try again.',
      ),
      DioExceptionType.connectionError => const ApiException(
        'No connection. Check your network and try again.',
      ),
      DioExceptionType.badResponse => ApiException._fromStatus(
        error.response?.statusCode,
      ),
      _ => const ApiException("Something went wrong. That's on us."),
    };
  }

  factory ApiException._fromStatus(int? status) => switch (status) {
    401 => const ApiException(
      'TMDB rejected the API key. Check your build configuration.',
      isRetryable: false,
    ),
    404 => const ApiException(
      "That title isn't in the TMDB catalogue.",
      isRetryable: false,
    ),
    429 => const ApiException('Too many requests. Give TMDB a moment.'),
    _ => const ApiException('TMDB is having trouble. Try again shortly.'),
  };

  final String message;
  final bool isRetryable;

  @override
  String toString() => 'ApiException: $message';
}
