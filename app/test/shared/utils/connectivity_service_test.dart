import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mindpal_app/shared/utils/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityService service;

  setUp(() {
    mockConnectivity = MockConnectivity();
    service = ConnectivityService(mockConnectivity);
  });

  tearDown(() {
    service.dispose();
  });

  group('ConnectivityService', () {
    test('checkConnectivity returns online for wifi', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final status = await service.checkConnectivity();

      expect(status, equals(ConnectivityStatus.online));
      expect(service.isOnline, isTrue);
      expect(service.isOffline, isFalse);
    });

    test('checkConnectivity returns online for mobile', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      final status = await service.checkConnectivity();

      expect(status, equals(ConnectivityStatus.online));
    });

    test('checkConnectivity returns online for ethernet', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.ethernet]);

      final status = await service.checkConnectivity();

      expect(status, equals(ConnectivityStatus.online));
    });

    test('checkConnectivity returns online for vpn', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.vpn]);

      final status = await service.checkConnectivity();

      expect(status, equals(ConnectivityStatus.online));
    });

    test('checkConnectivity returns offline for none', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final status = await service.checkConnectivity();

      expect(status, equals(ConnectivityStatus.offline));
      expect(service.isOnline, isFalse);
      expect(service.isOffline, isTrue);
    });

    test('checkConnectivity returns offline for empty list', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => []);

      final status = await service.checkConnectivity();

      expect(status, equals(ConnectivityStatus.offline));
    });

    test('checkConnectivity handles exceptions gracefully', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenThrow(Exception('Network error'));

      final status = await service.checkConnectivity();

      expect(status, equals(ConnectivityStatus.unknown));
    });

    test('initial currentStatus is unknown', () {
      expect(service.currentStatus, equals(ConnectivityStatus.unknown));
    });
  });

  group('ConnectivityStatus', () {
    test('online status is distinct', () {
      expect(ConnectivityStatus.online, isNot(ConnectivityStatus.offline));
      expect(ConnectivityStatus.online, isNot(ConnectivityStatus.unknown));
    });

    test('offline status is distinct', () {
      expect(ConnectivityStatus.offline, isNot(ConnectivityStatus.online));
      expect(ConnectivityStatus.offline, isNot(ConnectivityStatus.unknown));
    });

    test('unknown status is distinct', () {
      expect(ConnectivityStatus.unknown, isNot(ConnectivityStatus.online));
      expect(ConnectivityStatus.unknown, isNot(ConnectivityStatus.offline));
    });
  });
}
