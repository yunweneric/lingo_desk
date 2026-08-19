import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the platform's browser.
///
/// Release assets are served with a download disposition, so the same
/// call both downloads a build and follows an ordinary link.
Future<void> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
