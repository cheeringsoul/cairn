import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// True when running on a desktop shell (macOS / Windows / Linux) or
/// the web, i.e. any environment where mobile-only URL schemes like
/// `weixin://` or `iosamap://` have no handler and should be filtered.
///
/// Centralized here so services/, widgets/, and pages/ all agree on
/// the same definition — earlier copies drifted between `Platform.is*`
/// and `defaultTargetPlatform ==`.
bool get isDesktopPlatform {
  if (kIsWeb) return true;
  final p = defaultTargetPlatform;
  return p == TargetPlatform.macOS ||
      p == TargetPlatform.windows ||
      p == TargetPlatform.linux;
}

/// Schemes a desktop browser / mail client can actually handle.
/// Everything else (weixin, iosamap, diditaxi, …) is mobile-only and
/// should be dropped before being surfaced as a link.
bool isWebUrlScheme(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final s = uri.scheme.toLowerCase();
  return s == 'http' || s == 'https' || s == 'mailto';
}

/// `true` if the URL is safe to open on the current platform. On
/// desktop, restricts to web schemes; on mobile, trusts all schemes.
bool isUrlOpenableHere(String url) =>
    isDesktopPlatform ? isWebUrlScheme(url) : true;
