import 'package:web/web.dart' as web;
import 'package:mindpal_app/shared/services/storage_interface.dart';

/// Web implementation of StorageInterface using browser's localStorage.
/// This avoids the MissingPluginException that path_provider throws on web.
class WebStorage implements StorageInterface {
  final web.Storage _localStorage = web.window.localStorage;

  @override
  Future<String> getStorageDirectoryPath() async {
    // On web, we use localStorage instead of file system.
    // Return a placeholder path for compatibility with code that expects a path.
    return 'web_storage://localStorage';
  }

  @override
  Future<String?> getItem(String key) async {
    return _localStorage.getItem(key);
  }

  @override
  Future<void> setItem(String key, String value) async {
    _localStorage.setItem(key, value);
  }

  @override
  Future<void> removeItem(String key) async {
    _localStorage.removeItem(key);
  }

  @override
  Future<void> clear() async {
    _localStorage.clear();
  }
}

/// Factory function to create the appropriate storage for the current platform.
/// This file is conditionally imported on web platform.
StorageInterface createStorage() => WebStorage();
