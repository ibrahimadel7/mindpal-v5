import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:mindpal_app/theme.dart';

/// Error details for logging and display.
class ErrorDetails {
  const ErrorDetails({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    this.context,
  });

  final Object error;
  final StackTrace stackTrace;
  final DateTime timestamp;
  final String? context;

  @override
  String toString() => 'ErrorDetails(error: $error, context: $context)';
}

/// Callback for error reporting.
typedef OnError = void Function(ErrorDetails details);

/// Error boundary widget that catches errors in its child widget tree.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
    this.errorContext,
  });

  /// The child widget tree to wrap.
  final Widget child;

  /// Custom fallback widget to show on error. If null, shows default error UI.
  final Widget Function(Object error, VoidCallback retry)? fallback;

  /// Callback for error reporting/logging.
  final OnError? onError;

  /// Context string for error reports (e.g., screen name).
  final String? errorContext;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Register error handler for this zone
    FlutterError.onError = _handleFlutterError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    _reportError(details.exception, details.stack ?? StackTrace.current);
    setState(() {
      _error = details.exception;
    });
  }

  void _reportError(Object error, StackTrace stackTrace) {
    final details = ErrorDetails(
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: widget.errorContext,
    );

    widget.onError?.call(details);

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('ErrorBoundary caught error in ${widget.errorContext}:');
      debugPrint('$error');
      debugPrint('$stackTrace');
    }
  }

  void _retry() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.fallback != null) {
        return widget.fallback!(_error!, _retry);
      }
      return _DefaultErrorWidget(error: _error!, onRetry: _retry);
    }

    return widget.child;
  }
}

/// Default error display widget.
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: isDark ? MindPalColors.emotionAnger : Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'An unexpected error occurred. Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? MindPalColors.darkTextSecondary
                        : MindPalColors.ink700,
                  ),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? MindPalColors.darkSurface
                      : MindPalColors.sand100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: isDark
                            ? MindPalColors.darkTextSecondary
                            : MindPalColors.ink700,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Async error boundary for handling errors in FutureBuilder/StreamBuilder.
class AsyncErrorBoundary extends StatelessWidget {
  const AsyncErrorBoundary({
    super.key,
    required this.error,
    required this.onRetry,
    this.message,
  });

  final Object error;
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return _DefaultErrorWidget(error: error, onRetry: onRetry);
  }
}

/// Extension to wrap widgets with error boundary easily.
extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary({
    String? context,
    OnError? onError,
    Widget Function(Object error, VoidCallback retry)? fallback,
  }) {
    return ErrorBoundary(
      errorContext: context,
      onError: onError,
      fallback: fallback,
      child: this,
    );
  }
}

/// Zone-based error capturing for async operations.
R runWithErrorCapture<R>(
  R Function() body, {
  required void Function(Object error, StackTrace stack) onError,
}) {
  return runZonedGuarded(body, onError) as R;
}
