import 'dart:io' show Platform;

import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;

/// Returns an [http.Client] that respects system proxy / VPN on Apple
/// platforms.  On iOS / macOS this delegates to `URLSession` via
/// `cupertino_http`, which automatically honours the system proxy
/// configuration and VPN tunnels. On other platforms (Android) it
/// falls back to the default `dart:io`-backed client.
http.Client createPlatformClient() {
  if (Platform.isIOS || Platform.isMacOS) {
    return CupertinoClient.defaultSessionConfiguration();
  }
  return http.Client();
}
