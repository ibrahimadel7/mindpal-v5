import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindpal_app/shared/utils/retry_helper.dart';

void main() {
  group('RetryHelper', () {
    test('executes operation successfully on first attempt', () async {
      final helper = RetryHelper(const RetryConfig(maxAttempts: 3));
      var callCount = 0;

      final result = await helper.execute(() async {
        callCount++;
        return 'success';
      });

      expect(result.success, isTrue);
      expect(result.data, equals('success'));
      expect(result.attempts, equals(1));
      expect(callCount, equals(1));
    });

    test('retries on failure and succeeds on second attempt', () async {
      final helper = RetryHelper(const RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      ));
      var callCount = 0;

      final result = await helper.execute(
        () async {
          callCount++;
          if (callCount < 2) {
            throw TimeoutException('Temporary failure');
          }
          return 'success';
        },
      );

      expect(result.success, isTrue);
      expect(result.data, equals('success'));
      expect(result.attempts, equals(2));
      expect(callCount, equals(2));
    });

    test('fails after max attempts', () async {
      final helper = RetryHelper(const RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      ));
      var callCount = 0;

      final result = await helper.execute(
        () async {
          callCount++;
          throw TimeoutException('Persistent failure');
        },
      );

      expect(result.success, isFalse);
      expect(result.error, isA<TimeoutException>());
      expect(result.attempts, equals(3));
      expect(callCount, equals(3));
    });

    test('respects shouldRetry callback', () async {
      final helper = RetryHelper(const RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      ));
      var callCount = 0;

      final result = await helper.execute(
        () async {
          callCount++;
          throw Exception('Non-retryable');
        },
        shouldRetry: (error) => false,
      );

      expect(result.success, isFalse);
      expect(result.attempts, equals(1));
      expect(callCount, equals(1));
    });

    test('executeOrThrow throws on final failure', () async {
      final helper = RetryHelper(const RetryConfig(
        maxAttempts: 2,
        initialDelay: Duration(milliseconds: 10),
      ));

      expect(
        () => helper.executeOrThrow(
          () async {
            throw TimeoutException('Always fails');
          },
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('executeOrThrow returns data on success', () async {
      final helper = RetryHelper(const RetryConfig(maxAttempts: 2));

      final result = await helper.executeOrThrow(() async => 42);

      expect(result, equals(42));
    });
  });

  group('RetryConfig', () {
    test('default config has expected values', () {
      const config = RetryConfig();

      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(const Duration(milliseconds: 500)));
      expect(config.maxDelay, equals(const Duration(seconds: 30)));
      expect(config.backoffMultiplier, equals(2.0));
    });

    test('network preset has expected values', () {
      const config = RetryConfig.network;

      expect(config.maxAttempts, equals(3));
    });

    test('critical preset has more attempts', () {
      const config = RetryConfig.critical;

      expect(config.maxAttempts, equals(5));
    });

    test('light preset has fewer attempts', () {
      const config = RetryConfig.light;

      expect(config.maxAttempts, equals(2));
    });
  });

  group('RetryResult', () {
    test('success factory creates successful result', () {
      final result = RetryResult.success('data', attempts: 2);

      expect(result.success, isTrue);
      expect(result.data, equals('data'));
      expect(result.attempts, equals(2));
      expect(result.error, isNull);
    });

    test('failure factory creates failed result', () {
      final error = Exception('test error');
      final result = RetryResult.failure(error, attempts: 3);

      expect(result.success, isFalse);
      expect(result.data, isNull);
      expect(result.attempts, equals(3));
      expect(result.error, equals(error));
    });

    test('dataOrThrow returns data for successful result', () {
      final result = RetryResult.success('data');

      expect(result.dataOrThrow, equals('data'));
    });

    test('dataOrThrow throws for failed result', () {
      final result = RetryResult.failure(Exception('error'));

      expect(() => result.dataOrThrow, throwsException);
    });
  });
}
