import 'package:app_links/app_links.dart';

/// Thin wrapper over [AppLinks] so deep-link handling can be unit tested and the
/// rest of the app depends on a small surface rather than the plugin directly.
class DeepLinkService {
  DeepLinkService([AppLinks? appLinks]) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  /// The link that cold-launched the app, if any.
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  /// Links delivered while the app is already running.
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}
