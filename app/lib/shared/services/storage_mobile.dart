import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mindpal_app/shared/services/storage_interface.dart';

/// Mobile implementation of StorageInterface using path_provider.
/// This is used on Android, iOS, macOS, Windows, Linux platforms.
class MobileStorage implements StorageInterface {
  Directory? _appDir;

  @override
  Future<String> getStorageDirectoryPath() async {
    _appDir ??= await getApplicationSupportDirectory();
    return _appDir!.path;
  }

  @override
  Future<String?> getItem(String key) async {
    final dir = await getStorageDirectoryPath();
    final file = File('$dir/$key');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  @override
  Future<void> setItem(String key, String value) async {
    final dir = await getStorageDirectoryPath();
    final file = File('$dir/$key');
    await file.writeAsString(value);
  }

  @override
  Future<void> removeItem(String key) async {
    final dir = await getStorageDirectoryPath();
    final file = File('$dir/$key');
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clear() async {
    final dir = await getStorageDirectoryPath();
    final directory = Directory(dir);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    _appDir = null;
  }
}

/// Factory function to create the appropriate storage for the current platform.
/// This file is conditionally imported on non-web platforms.
StorageInterface createStorage() => MobileStorage();
