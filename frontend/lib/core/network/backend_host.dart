import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// The dev machine's LAN IP, for iOS to reach the backend — the simulator
/// can also use `localhost`, but a physical iPhone can't. Override at run
/// time instead of editing this when the Mac's address changes (check it
/// with `ipconfig getifaddr en0`):
///   flutter run --dart-define=API_HOST=192.168.1.42
const _apiHost = String.fromEnvironment('API_HOST', defaultValue: '192.168.1.107');

/// Resolves to just the host (no scheme, no port) so callers can build
/// either an `http://` API URL or a `ws://` socket URL from it.
String get backendHost {
  if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
  if (!kIsWeb && Platform.isIOS) return _apiHost;
  return 'localhost';
}
