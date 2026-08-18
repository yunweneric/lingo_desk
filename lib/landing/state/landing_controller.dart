import 'package:flutter/foundation.dart';

import '../../core/theme/lingo_desk_palette.dart';
import '../data/github_release.dart';
import '../data/github_service.dart';

/// Everything the landing page keeps in memory: the look a visitor has
/// picked, and what GitHub says about the newest build.
///
/// Deliberately a plain [ChangeNotifier] rather than the app's BLoC +
/// GetIt stack — the site has no persistence and no domain layer, and
/// keeping it out means `main_landing.dart` never pulls the injection
/// container into the web bundle.
class LandingController extends ChangeNotifier {
  LandingController({GithubService? service})
    : _service = service ?? GithubService();

  final GithubService _service;

  LingoDeskThemeVariant _variant = LingoDeskThemeVariant.teal;
  bool _isDark = true;
  ReleaseState _release = const ReleaseLoading();
  int? _stars;

  /// The palette the whole page is painted in. Visitors change it from
  /// the "built with Flutter" section, which is the point: one tap
  /// repaints every section, live.
  LingoDeskThemeVariant get variant => _variant;

  /// Dark by default — the product is a developer tool and every
  /// screenshot on the page is dark.
  bool get isDark => _isDark;

  ReleaseState get release => _release;
  int? get stars => _stars;

  /// The build matching the browser the visitor is using.
  ///
  /// On web Flutter derives [defaultTargetPlatform] from the user agent,
  /// so this needs no JavaScript interop. Linux and iOS resolve to null:
  /// no workflow publishes those, and the UI routes them to the source
  /// build instead of offering a download that cannot exist.
  static DownloadTarget? get visitorTarget => switch (defaultTargetPlatform) {
    TargetPlatform.macOS => DownloadTarget.macos,
    TargetPlatform.windows => DownloadTarget.windowsInstaller,
    TargetPlatform.android => DownloadTarget.android,
    _ => null,
  };

  /// The asset the hero's primary button should hand over, when the
  /// release is resolved and actually carries a build for this visitor.
  ReleaseAsset? get suggestedAsset {
    final state = _release;
    final target = visitorTarget;
    if (state is! ReleaseReady || target == null) {
      return null;
    }
    return state.release.assetFor(target);
  }

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _release = const ReleaseLoading();
      notifyListeners();
    }

    final state = await _service.latestRelease(refresh: refresh);
    _release = state;
    notifyListeners();

    final count = await _service.stars();
    if (count != null && count != _stars) {
      _stars = count;
      notifyListeners();
    }
  }

  void setVariant(LingoDeskThemeVariant variant) {
    if (variant == _variant) {
      return;
    }
    _variant = variant;
    notifyListeners();
  }

  void toggleBrightness() {
    _isDark = !_isDark;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
