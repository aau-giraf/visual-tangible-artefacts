import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _log = Logger('RetryHelper');

/// HTTP status codes that should never be retried because the request itself
/// is the problem, not a transient server / network issue.
const _nonRetryableStatusCodes = {400, 401, 403, 404, 405, 409, 422};

/// Result of an operation executed through [RetryHelper].
class RetryResult<T> {
  /// The value returned by the operation, or `null` if all attempts failed.
  final T? value;

  /// Whether the operation ultimately succeeded.
  final bool succeeded;

  /// Number of attempts made (1 = succeeded on first try).
  final int attempts;

  /// The last error encountered, if the operation failed.
  final Object? lastError;

  const RetryResult._({
    this.value,
    required this.succeeded,
    required this.attempts,
    this.lastError,
  });

  factory RetryResult.success(T value, {int attempts = 1}) =>
      RetryResult._(value: value, succeeded: true, attempts: attempts);

  factory RetryResult.failure({required int attempts, Object? lastError}) =>
      RetryResult._(succeeded: false, attempts: attempts, lastError: lastError);
}

/// Utility for retrying async operations with exponential backoff and jitter.
///
/// Usage:
/// ```dart
/// final result = await RetryHelper.run(
///   () => apiProvider.fetchAsJson('Artefacts', headers: headers),
///   label: 'fetchArtefacts',
/// );
/// if (result.succeeded) { /* use result.value */ }
/// ```
class RetryHelper {
  /// Execute [operation] with retry + exponential backoff.
  ///
  /// * [maxAttempts] — total number of tries (including the first).
  /// * [initialDelay] — base delay before the first retry (doubled each time).
  /// * [shouldRetry] — optional predicate; when provided, only retry if it
  ///   returns `true` for the caught exception. Defaults to retrying all.
  /// * [label] — human-readable name shown in log messages.
  static Future<RetryResult<T>> run<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    bool Function(Object error)? shouldRetry,
    String label = 'operation',
  }) async {
    final random = Random();
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await operation();
        if (attempt > 1) {
          _log.info('$label succeeded on attempt $attempt');
        }
        return RetryResult.success(result, attempts: attempt);
      } catch (e) {
        lastError = e;

        if (shouldRetry != null && !shouldRetry(e)) {
          _log.fine('$label failed with non-retryable error: $e');
          return RetryResult.failure(attempts: attempt, lastError: e);
        }

        if (attempt == maxAttempts) {
          _log.warning(
              '$label failed after $maxAttempts attempts. Last error: $e');
          return RetryResult.failure(attempts: attempt, lastError: e);
        }

        // Exponential backoff: delay * 2^(attempt-1) + random jitter
        final backoff = initialDelay * pow(2, attempt - 1);
        final jitter = Duration(
          milliseconds: random.nextInt(backoff.inMilliseconds ~/ 2 + 1),
        );
        final totalDelay = backoff + jitter;

        _log.info(
          '$label attempt $attempt failed ($e). '
          'Retrying in ${totalDelay.inMilliseconds}ms…',
        );
        await Future.delayed(totalDelay);
      }
    }

    // Should never reach here, but just in case.
    return RetryResult.failure(attempts: maxAttempts, lastError: lastError);
  }

  /// Convenience wrapper for HTTP calls that returns an [http.Response?].
  ///
  /// Automatically skips retry for non-retryable HTTP status codes (401, 403,
  /// 404 etc.) by inspecting the response rather than relying on exceptions.
  ///
  /// Returns `null` only if all attempts produce null responses (e.g. network
  /// errors caught by ApiProvider).
  static Future<RetryResult<http.Response?>> runHttp(
    Future<http.Response?> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    String label = 'HTTP request',
  }) async {
    final random = Random();
    http.Response? lastResponse;
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await operation();
        lastResponse = response;

        if (response == null) {
          // Network failure — ApiProvider returns null on exception
          if (attempt == maxAttempts) {
            _log.warning('$label: all $maxAttempts attempts returned null');
            return RetryResult.failure(attempts: attempt);
          }
        } else if (response.statusCode >= 200 && response.statusCode < 300) {
          if (attempt > 1) {
            _log.info('$label succeeded on attempt $attempt');
          }
          return RetryResult.success(response, attempts: attempt);
        } else if (_nonRetryableStatusCodes.contains(response.statusCode)) {
          _log.fine(
              '$label returned non-retryable status ${response.statusCode}');
          return RetryResult.success(response, attempts: attempt);
        } else {
          // 5xx or other retryable status
          if (attempt == maxAttempts) {
            _log.warning(
              '$label failed after $maxAttempts attempts. '
              'Last status: ${response.statusCode}',
            );
            return RetryResult.success(response, attempts: attempt);
          }
        }
      } catch (e) {
        lastError = e;
        if (attempt == maxAttempts) {
          _log.warning(
              '$label failed after $maxAttempts attempts. Last error: $e');
          return RetryResult.failure(attempts: attempt, lastError: e);
        }
      }

      // Backoff before next attempt
      final backoff = initialDelay * pow(2, attempt - 1);
      final jitter = Duration(
        milliseconds: random.nextInt(backoff.inMilliseconds ~/ 2 + 1),
      );
      final totalDelay = backoff + jitter;

      _log.info(
        '$label attempt $attempt failed. '
        'Retrying in ${totalDelay.inMilliseconds}ms…',
      );
      await Future.delayed(totalDelay);
    }

    // Fallback
    if (lastResponse != null) {
      return RetryResult.success(lastResponse, attempts: maxAttempts);
    }
    return RetryResult.failure(attempts: maxAttempts, lastError: lastError);
  }
}
