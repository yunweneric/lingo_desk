import '../../core/constants/github_repo.dart';
import '../../core/localization/export.dart';

// The repo constants live in core so the in-app updater can share them.
export '../../core/constants/github_repo.dart';

/// A build the release workflows publish, in the order the download
/// section lists them.
///
/// Linux and iOS are deliberately absent: no workflow produces them, so
/// the site sends those visitors to the source build instead of showing a
/// button that cannot resolve.
enum DownloadTarget {
  macos(label: 'macOS', detail: 'Disk image', extension: '.dmg'),
  windowsInstaller(label: 'Windows', detail: 'Installer', extension: '.exe'),
  windowsPortable(label: 'Windows', detail: 'Portable ZIP', extension: '.zip'),
  android(label: 'Android', detail: 'APK', extension: '.apk');

  const DownloadTarget({
    required this.label,
    required this.detail,
    required this.extension,
  });

  final String label;
  final String detail;
  final String extension;

  /// Headline used on the primary call to action for this target.
  String get cta => switch (this) {
    DownloadTarget.macos => LocaleKeys.landingCtaMacos.tr(),
    DownloadTarget.windowsInstaller ||
    DownloadTarget.windowsPortable => LocaleKeys.landingCtaWindows.tr(),
    DownloadTarget.android => LocaleKeys.landingCtaApk.tr(),
  };

  /// The caveat shown under the button, matching the release notes.
  String? get warning => switch (this) {
    DownloadTarget.macos => LocaleKeys.landingWarningMacos.tr(),
    DownloadTarget.windowsInstaller ||
    DownloadTarget.windowsPortable => LocaleKeys.landingWarningWindows.tr(),
    DownloadTarget.android => null,
  };

  /// Classifies a release asset filename.
  ///
  /// The patterns mirror what `.github/workflows/release.yml` and
  /// `build_apk.yml` name their outputs. Anything unrecognised (the
  /// Play Store `.aab`, source archives) returns null and is not listed.
  static DownloadTarget? classify(String filename) {
    final name = filename.toLowerCase();
    // build_apk.yml attaches a debug APK beside the release one. It is a
    // build artifact, not something to hand a visitor.
    if (name.contains('debug')) {
      return null;
    }
    if (name.endsWith('.dmg')) {
      return DownloadTarget.macos;
    }
    if (name.endsWith('.exe')) {
      return DownloadTarget.windowsInstaller;
    }
    if (name.endsWith('.zip') && name.contains('windows')) {
      return DownloadTarget.windowsPortable;
    }
    if (name.endsWith('.apk')) {
      return DownloadTarget.android;
    }
    return null;
  }
}

/// One downloadable file attached to a release.
class ReleaseAsset {
  const ReleaseAsset({
    required this.target,
    required this.filename,
    required this.downloadUrl,
    required this.sizeInBytes,
  });

  final DownloadTarget target;
  final String filename;
  final String downloadUrl;
  final int sizeInBytes;

  /// Human size, e.g. `48.2 MB`. Binaries here are always megabytes.
  String get readableSize {
    final megabytes = sizeInBytes / (1024 * 1024);
    if (megabytes < 1) {
      return '${(sizeInBytes / 1024).round()} KB';
    }
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  static ReleaseAsset? fromJson(Map<String, dynamic> json) {
    final filename = json['name'] as String? ?? '';
    final target = DownloadTarget.classify(filename);
    final downloadUrl = json['browser_download_url'] as String?;
    if (target == null || downloadUrl == null) {
      return null;
    }
    return ReleaseAsset(
      target: target,
      filename: filename,
      downloadUrl: downloadUrl,
      sizeInBytes: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The newest published release and the builds attached to it.
class GithubRelease {
  const GithubRelease({
    required this.tag,
    required this.htmlUrl,
    required this.publishedAt,
    required this.assets,
  });

  final String tag;
  final String htmlUrl;
  final DateTime? publishedAt;
  final List<ReleaseAsset> assets;

  /// The version without its `v` prefix, for display.
  String get version => tag.startsWith('v') ? tag.substring(1) : tag;

  bool get hasDownloads => assets.isNotEmpty;

  ReleaseAsset? assetFor(DownloadTarget target) {
    for (final asset in assets) {
      if (asset.target == target) {
        return asset;
      }
    }
    return null;
  }

  /// `18 Aug 2026`, in the visitor's language — or null when GitHub omits
  /// the date.
  String? get publishedLabel {
    final date = publishedAt;
    return date == null ? null : AppLocalization.formatDate(date);
  }

  static GithubRelease fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assets'];
    final assets = <ReleaseAsset>[];
    if (rawAssets is List) {
      for (final entry in rawAssets) {
        if (entry is Map<String, dynamic>) {
          final asset = ReleaseAsset.fromJson(entry);
          if (asset != null) {
            assets.add(asset);
          }
        }
      }
    }
    assets.sort((a, b) => a.target.index.compareTo(b.target.index));

    return GithubRelease(
      tag: json['tag_name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? GithubRepo.releases,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      assets: assets,
    );
  }
}

/// What the download section knows right now.
sealed class ReleaseState {
  const ReleaseState();
}

/// The request is in flight.
class ReleaseLoading extends ReleaseState {
  const ReleaseLoading();
}

/// A release exists and carries at least one recognised build.
class ReleaseReady extends ReleaseState {
  const ReleaseReady(this.release);

  final GithubRelease release;
}

/// The repository has no published release yet, or the newest one carries
/// no recognised build. Visitors are pointed at the source build.
class ReleasePending extends ReleaseState {
  const ReleasePending();
}

/// The API could not be reached — offline, rate limited, or unexpected
/// payload. The section degrades to plain links rather than dead-ending.
class ReleaseUnavailable extends ReleaseState {
  const ReleaseUnavailable(this.reason);

  final String reason;
}
