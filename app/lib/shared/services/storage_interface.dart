/// Abstract interface for platform-specific storage operations.
/// This allows the same API to work on both web and mobile platforms.
abstract class StorageInterface {
  /// Returns the directory path suitable for storing application support files.
  /// On mobile, this returns the application support directory.
  /// On web, this returns a placeholder since web uses localStorage instead.
  Future<String> getStorageDirectoryPath();

  /// Stores a value in persistent storage.
  Future<void> setItem(String key, String value);

  /// Retrieves a value from persistent storage.
  Future<String?> getItem(String key);

  /// Removes a value from persistent storage.
  Future<void> removeItem(String key);

  /// Clears all stored values.
  Future<void> clear();
}
