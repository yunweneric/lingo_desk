import 'package:flutter/foundation.dart';

/// The build of a release this machine can actually run.
///
/// Mirrors what `.github/workflows/release.yml` attaches to a tag. Linux
/// and iOS have no published build, so they resolve to [unsupported] and
/// the card sends those users to the releases page instead of offering a
/// file that does not exist.
enum UpdatePlatform {
  macos('macOS'),
  windows('Windows'),
  android('Android'),
  unsupported('');

  const UpdatePlatform(this.label);

  /// Shown when a release carries nothing for this platform.
  final String label;

  bool get hasBuild => this != UpdatePlatform.unsupported;

  /// What the running app is. Web is deliberately unsupported: the landing
  /// page is the only web target and it has its own download section.
  static UpdatePlatform get current {
    if (kIsWeb) {
      return UpdatePlatform.unsupported;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS => UpdatePlatform.macos,
      TargetPlatform.windows => UpdatePlatform.windows,
      TargetPlatform.android => UpdatePlatform.android,
      _ => UpdatePlatform.unsupported,
    };
  }

  /// Whether [filename] is the build this platform should install.
  ///
  /// The Play bundle and any debug artifact are rejected: neither is
  /// something to hand a user. Windows takes the installer rather than the
  /// portable ZIP, since the installer is what an update should replace.
  bool matches(String filename) {
    final name = filename.toLowerCase();
    if (name.contains('debug') || name.endsWith('.aab')) {
      return false;
    }
    return switch (this) {
      UpdatePlatform.macos => name.endsWith('.dmg'),
      UpdatePlatform.windows => name.endsWith('.exe'),
      UpdatePlatform.android => name.endsWith('.apk'),
      UpdatePlatform.unsupported => false,
    };
  }
}

/// The file to download for this platform.
class UpdateAsset {
  const UpdateAsset({
    required this.filename,
    required this.downloadUrl,
    required this.sizeInBytes,
  });

  final String filename;
  final String downloadUrl;
  final int sizeInBytes;

  /// Human size, e.g. `22.0 MB`.
  String get readableSize {
    final megabytes = sizeInBytes / (1024 * 1024);
    if (megabytes < 1) {
      return '${(sizeInBytes / 1024).round()} KB';
    }
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  static UpdateAsset? fromJson(Map<String, dynamic> json) {
    final filename = json['name'] as String?;
    final downloadUrl = json['browser_download_url'] as String?;
    if (filename == null || downloadUrl == null) {
      return null;
    }
    return UpdateAsset(
      filename: filename,
      downloadUrl: downloadUrl,
      sizeInBytes: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A published release, reduced to what the update card needs.
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.notesUrl,
    required this.asset,
  });

  /// Release version without its `v` prefix, e.g. `1.0.2`.
  final String version;

  /// The release page, used for the notes link and as the fallback when
  /// this platform has no attached build.
  final String notesUrl;

  /// The build for the running platform, or null when the release carries
  /// none.
  final UpdateAsset? asset;

  static AppUpdate fromJson(
    Map<String, dynamic> json, {
    required UpdatePlatform platform,
  }) {
    final tag = json['tag_name'] as String? ?? '';
    final rawAssets = json['assets'];
    UpdateAsset? match;
    if (rawAssets is List) {
      for (final entry in rawAssets) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final asset = UpdateAsset.fromJson(entry);
        if (asset != null && platform.matches(asset.filename)) {
          match = asset;
          break;
        }
      }
    }

    return AppUpdate(
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      notesUrl: json['html_url'] as String? ?? '',
      asset: match,
    );
  }
}

/// Why a check could not answer. Kept as a kind rather than a message so
/// the service stays free of localisation and the card picks the wording.
enum UpdateFailure { offline, rateLimited, unexpected }

/// What the update card knows right now.
sealed class UpdateStatus {
  const UpdateStatus();
}

/// Nothing asked yet.
class UpdateIdle extends UpdateStatus {
  const UpdateIdle();
}

/// A check is in flight.
class UpdateChecking extends UpdateStatus {
  const UpdateChecking();
}

/// The newest release is not newer than what is running.
class UpdateUpToDate extends UpdateStatus {
  const UpdateUpToDate();
}

/// A newer release exists. [update] carries a build for this platform.
class UpdateAvailable extends UpdateStatus {
  const UpdateAvailable(this.update);

  final AppUpdate update;
}

/// A newer release exists but publishes nothing this platform can run —
/// Linux, iOS, or a release whose build job failed.
class UpdateNoBuild extends UpdateStatus {
  const UpdateNoBuild(this.update);

  final AppUpdate update;
}

/// GitHub could not be asked. The card degrades to the releases link.
class UpdateCheckFailed extends UpdateStatus {
  const UpdateCheckFailed(this.failure);

  final UpdateFailure failure;
}

/// Orders two dotted versions, ignoring a `v` prefix and any `-sha` or
/// `+build` suffix.
///
/// Returns a negative number when [a] is older than [b], zero when they
/// are the same release, positive when [a] is newer. A locally built app
/// reports the pubspec version, which is usually behind the newest tag —
/// that is the check working, not a bug.
int compareVersions(String a, String b) {
  final left = _parseVersion(a);
  final right = _parseVersion(b);
  for (var i = 0; i < 3; i++) {
    final difference = left[i] - right[i];
    if (difference != 0) {
      return difference;
    }
  }
  return 0;
}

List<int> _parseVersion(String value) {
  final cleaned = value
      .trim()
      .replaceFirst(RegExp('^v'), '')
      .split(RegExp(r'[-+]'))
      .first;
  final parts = cleaned.split('.');
  return List<int>.generate(
    3,
    (index) => index < parts.length ? int.tryParse(parts[index]) ?? 0 : 0,
  );
}
