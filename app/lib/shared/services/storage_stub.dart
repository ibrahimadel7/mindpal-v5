import 'package:mindpal_app/shared/services/storage_interface.dart';

/// Stub implementation - should never be called at runtime.
/// The actual implementation is provided via conditional imports.
StorageInterface createStorage() =>
    throw UnsupportedError(
      'Cannot create storage without a platform-specific implementation. '
      'Ensure conditional imports are set up correctly.',
    );
