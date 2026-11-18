import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

/// Configuration for retry behavior with exponential backoff.
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.jitterFactor = 0.1,
    this.retryableStatusCodes = const {408, 429, 500, 502, 503, 504},
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final double jitterFactor;
  final Set<int> retryableStatusCodes;

  /// Default config for network requests.
  static const network = RetryConfig();

  /// More aggressive retry for critical operations.
  static const critical = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 200),
  );

  /// Quick retry for non-critical operations.
  static const light = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 300),
  );
}

/// Result of a retry operation.
class RetryResult<T> {
  const RetryResult._({
    required this.success,
    this.data,
    this.error,
    this.attempts = 0,
  });

  factory RetryResult.success(T data, {int attempts = 1}) =>
      RetryResult._(success: true, data: data, attempts: attempts);

  factory RetryResult.failure(Object error, {int attempts = 0}) =>
      RetryResult._(success: false, error: error, attempts: attempts);

  final bool success;
  final T? data;
  final Object? error;
  final int attempts;

  T get dataOrThrow {
    if (success && data != null) return data as T;
    throw error ?? Exception('No data available');
  }
}

/// Helper for executing operations with exponential backoff retry.
class RetryHelper {
  const RetryHelper([this.config = const RetryConfig()]);

  final RetryConfig config;

  /// Execute an async operation with retry logic.
  Future<RetryResult<T>> execute<T>(
    Future<T> Function() operation, {
    bool Function(Object error)? shouldRetry,
  }) async {
    Object? lastError;
    int attempt = 0;

    while (attempt < config.maxAttempts) {
      attempt++;
      try {
        final result = await operation();
        return RetryResult.success(result, attempts: attempt);
      } catch (e) {
        lastError = e;

        if (attempt >= config.maxAttempts) {
          break;
        }

        final shouldRetryError = shouldRetry?.call(e) ?? _defaultShouldRetry(e);
        if (!shouldRetryError) {
          break;
        }

        final delay = _calculateDelay(attempt);
        await Future<void>.delayed(delay);
      }
    }

    return RetryResult.failure(lastError ?? Exception('Unknown error'),
        attempts: attempt);
  }

  /// Execute with retry and throw on final failure.
  Future<T> executeOrThrow<T>(
    Future<T> Function() operation, {
    bool Function(Object error)? shouldRetry,
  }) async {
    final result = await execute(operation, shouldRetry: shouldRetry);
    return result.dataOrThrow;
  }

  Duration _calculateDelay(int attempt) {
    final baseDelay = config.initialDelay.inMilliseconds *
        pow(config.backoffMultiplier, attempt - 1);

    final jitter = baseDelay * config.jitterFactor * (Random().nextDouble() - 0.5) * 2;
    final delayMs = (baseDelay + jitter).round();

    return Duration(
      milliseconds: min(delayMs, config.maxDelay.inMilliseconds),
    );
  }

  bool _defaultShouldRetry(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return statusCode != null &&
              config.retryableStatusCodes.contains(statusCode);
        default:
          return false;
      }
    }

    // Retry on network-related errors
    if (error is TimeoutException) return true;

    return false;
  }
}

/// Extension for adding retry capability to Dio.
extension DioRetryExtension on Dio {
  Future<Response<T>> getWithRetry<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    RetryConfig config = const RetryConfig(),
  }) async {
    final helper = RetryHelper(config);
    return helper.executeOrThrow(
      () => get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<Response<T>> postWithRetry<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    RetryConfig config = const RetryConfig(),
  }) async {
    final helper = RetryHelper(config);
    return helper.executeOrThrow(
      () => post<T>(path,
          data: data, queryParameters: queryParameters, options: options),
    );
  }
}
