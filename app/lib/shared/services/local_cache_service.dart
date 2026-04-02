import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:mindpal_app/shared/services/storage_interface.dart';
import 'package:mindpal_app/shared/services/storage_stub.dart'
    if (dart.library.html) 'package:mindpal_app/shared/services/storage_web.dart'
    if (dart.library.io) 'package:mindpal_app/shared/services/storage_mobile.dart';

class LocalCacheService {
  Isar? _isar;
  bool _disabled = false;
  StorageInterface? _storage;

  /// Returns the platform-specific storage implementation.
  StorageInterface get storage => _storage ??= createStorage();

  Future<Isar?> instance() async {
    // Web builds in this project use an in-memory chat cache only.
    if (kIsWeb || _disabled) {
      _disabled = true;
      return null;
    }

    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    try {
      final dirPath = await storage.getStorageDirectoryPath();
      _isar = await Isar.open(
        <CollectionSchema>[],
        directory: dirPath,
        name: 'mindpal_cache',
      );
      return _isar!;
    } catch (_) {
      _disabled = true;
      return null;
    }
  }

  Future<void> clearAll() async {
    final isar = await instance();
    if (isar == null) {
      return;
    }
    await isar.close(deleteFromDisk: true);
    _isar = null;
  }
}
