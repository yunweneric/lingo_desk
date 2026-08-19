import 'package:flutter/foundation.dart';

import 'app_update.dart';
import 'update_service.dart';

/// Drives the updates pane: one check against GitHub, then the download
/// of the build for this platform.
///
/// A [ChangeNotifier] rather than a bloc, like the other settings panes:
/// the pane writes straight through to the service instead of round-
/// tripping through events.
class UpdateController extends ChangeNotifier {
  UpdateController(this._service);

  final UpdateService _service;

  UpdateStatus _status = const UpdateIdle();
  String _installedVersion = '';
  bool _downloading = false;
  double? _progress;
  String? _savedPath;
  bool _downloadFailed = false;

  UpdateStatus get status => _status;

  /// The running app's version, empty until the first check resolves it.
  String get installedVersion => _installedVersion;

  bool get isChecking => _status is UpdateChecking;
  bool get isDownloading => _downloading;

  /// 0..1 while a download reports its size, null while it cannot.
  double? get progress => _progress;

  /// Where the finished download landed, or null when none has.
  String? get savedPath => _savedPath;

  /// Whether the last download attempt gave up.
  bool get downloadFailed => _downloadFailed;

  /// Checks once per app run unless the user asks again, so opening the
  /// pane twice does not spend two of GitHub's unauthenticated calls.
  Future<void> checkIfNeeded() async {
    if (_status is UpdateIdle) {
      await check();
    } else if (_installedVersion.isEmpty) {
      await _loadInstalledVersion();
    }
  }

  Future<void> check() async {
    if (_status is UpdateChecking) {
      return;
    }
    _status = const UpdateChecking();
    _savedPath = null;
    _downloadFailed = false;
    notifyListeners();

    await _loadInstalledVersion();
    _status = await _service.check();
    notifyListeners();
  }

  /// Fetches the build for this platform into the Downloads folder.
  ///
  /// Does nothing unless a check has resolved an update that actually
  /// carries a build.
  Future<void> download() async {
    final status = _status;
    if (_downloading || status is! UpdateAvailable) {
      return;
    }
    final asset = status.update.asset;
    if (asset == null) {
      return;
    }

    _downloading = true;
    _progress = 0;
    _savedPath = null;
    _downloadFailed = false;
    notifyListeners();

    try {
      _savedPath = await _service.download(
        asset,
        onProgress: (progress) {
          // A 20 MB download arrives in hundreds of chunks; repainting a
          // progress bar for each one is work nobody can see, so the UI
          // only hears about whole percents.
          if (progress != null &&
              _progress != null &&
              (progress - _progress!) < 0.01 &&
              progress < 1) {
            return;
          }
          _progress = progress;
          notifyListeners();
        },
      );
    } on UpdateDownloadException {
      _downloadFailed = true;
    } finally {
      _downloading = false;
      _progress = null;
      notifyListeners();
    }
  }

  /// Opens the folder holding the finished download.
  Future<void> revealDownload() async {
    final path = _savedPath;
    if (path == null) {
      return;
    }
    try {
      await _service.reveal(path);
    } on Exception {
      // The file is on disk either way; a file manager that refuses to
      // open is not worth an error state.
    }
  }

  Future<void> _loadInstalledVersion() async {
    _installedVersion = await _service.currentVersion();
  }
}
