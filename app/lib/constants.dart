import 'package:flutter/foundation.dart';

const String kBaseUrl = 'http://localhost:8000';
const int kUserId = 1;

// For physical Android/iOS devices, use your computer's local network IP
// Your current local IP: 192.168.100.3
// To find it again: `ip a` (Linux) or `ipconfig` (Windows)
const String kPhysicalDeviceUrl = 'http://192.168.100.3:8000';
const String kEmulatorUrl = 'http://10.0.2.2:8000'; // Android emulator only

String get resolvedBaseUrl {
  if (kIsWeb) {
    return kBaseUrl;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    // For physical devices, use local network IP
    // For emulators, use the special 10.0.2.2 alias
    // Default to physical device URL - most common case
    return kPhysicalDeviceUrl;
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // iOS simulator can use localhost directly
    // For physical iOS devices, use the local network IP
    return kBaseUrl;
  }

  return kBaseUrl;
}
