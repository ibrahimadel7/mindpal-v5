import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

/// Connectivity status enum for clearer semantics.
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Service for monitoring network connectivity.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  
  StreamController<ConnectivityStatus>? _statusController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _lastStatus = ConnectivityStatus.unknown;

  /// Current connectivity status.
  ConnectivityStatus get currentStatus => _lastStatus;

  /// Whether device is currently online.
  bool get isOnline => _lastStatus == ConnectivityStatus.online;

  /// Whether device is currently offline.
  bool get isOffline => _lastStatus == ConnectivityStatus.offline;

  /// Stream of connectivity status changes.
  Stream<ConnectivityStatus> get statusStream {
    _ensureInitialized();
    return _statusController!.stream;
  }

  /// Check current connectivity and update status.
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _lastStatus = _mapResults(results);
      return _lastStatus;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity: $e');
      return ConnectivityStatus.unknown;
    }
  }

  void _ensureInitialized() {
    if (_statusController != null) return;

    _statusController = StreamController<ConnectivityStatus>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final newStatus = _mapResults(results);
        if (newStatus != _lastStatus) {
          _lastStatus = newStatus;
          _statusController?.add(newStatus);
        }
      },
      onError: (Object error) {
        debugPrint('ConnectivityService: Stream error: $error');
      },
    );

    // Check initial status
    checkConnectivity();
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }

    // Consider online if any connection type is available (except none)
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.mobile:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.vpn:
        case ConnectivityResult.satellite:
          return ConnectivityStatus.online;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
          continue;
        case ConnectivityResult.none:
          continue;
      }
    }

    return ConnectivityStatus.offline;
  }

  /// Clean up resources.
  void dispose() {
    _stopListening();
    _statusController?.close();
    _statusController = null;
  }
}

/// Provider for connectivity service.
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
}

/// Provider for current connectivity status.
@riverpod
Stream<ConnectivityStatus> connectivityStatus(Ref ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
}

/// Provider for checking if currently online.
@riverpod
Future<bool> isOnline(Ref ref) async {
  final service = ref.watch(connectivityServiceProvider);
  final status = await service.checkConnectivity();
  return status == ConnectivityStatus.online;
}
