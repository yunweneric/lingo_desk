import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/github_repo.dart';
import '../utils/file_writer_stub.dart'
    if (dart.library.io) '../utils/file_writer_io.dart';
import 'app_update.dart';

/// Asks GitHub whether a newer LingoDesk has been published, and fetches
/// the build for this platform when one has.
///
/// It reads *releases*, not Actions artifacts: artifact downloads need an
/// authenticated token, while `releases/latest` is public and
/// unauthenticated — the same endpoint the landing page uses.
///
/// Nothing is ever installed for the user. The file lands in Downloads and
/// they run it themselves, which is the only honest option for builds that
/// ship unsigned.
class UpdateService {
  UpdateService({
    http.Client? client,
    this.apiBase = GithubRepo.api,
    UpdatePlatform? platform,
    String? currentVersion,
  }) : _client = client ?? http.Client(),
       platform = platform ?? UpdatePlatform.current,
       _currentVersion = currentVersion;

  final http.Client _client;

  /// Overridable so the update UI can be exercised against a repository
  /// that already publishes builds.
  final String apiBase;

  /// The build this machine can run. Injectable so a test can pretend to
  /// be Windows.
  final UpdatePlatform platform;

  String? _currentVersion;

  static const _timeout = Duration(seconds: 10);
  static const _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  /// The running app's version, e.g. `1.0.2`.
  ///
  /// This is the build name the release workflow stamps in from the tag,
  /// so it matches what GitHub publishes. A build run from a developer
  /// machine reports the pubspec version instead, which is normally
  /// behind the newest tag.
  Future<String> currentVersion() async {
    final cached = _currentVersion;
    if (cached != null) {
      return cached;
    }
    final info = await PackageInfo.fromPlatform();
    return _currentVersion = info.version;
  }

  /// Compares the newest published release against the running version.
  Future<UpdateStatus> check() async {
    final installed = await currentVersion();

    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$apiBase/releases/latest'), headers: _headers)
          .timeout(_timeout);
    } on TimeoutException {
      return const UpdateCheckFailed(UpdateFailure.offline);
    } on http.ClientException {
      return const UpdateCheckFailed(UpdateFailure.offline);
    }

    // 404 means the repository has never published a release. Nothing is
    // wrong and nothing is newer, so this reads as up to date.
    if (response.statusCode == 404) {
      return const UpdateUpToDate();
    }
    if (response.statusCode == 403 || response.statusCode == 429) {
      return const UpdateCheckFailed(UpdateFailure.rateLimited);
    }
    if (response.statusCode != 200) {
      return const UpdateCheckFailed(UpdateFailure.unexpected);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      return const UpdateCheckFailed(UpdateFailure.unexpected);
    }
    if (decoded is! Map<String, dynamic>) {
      return const UpdateCheckFailed(UpdateFailure.unexpected);
    }

    final update = AppUpdate.fromJson(decoded, platform: platform);
    if (update.version.isEmpty ||
        compareVersions(update.version, installed) <= 0) {
      return const UpdateUpToDate();
    }
    return update.asset == null
        ? UpdateNoBuild(update)
        : UpdateAvailable(update);
  }

  /// Downloads [asset] into the user's Downloads folder and returns the
  /// path it was written to.
  ///
  /// [onProgress] is called with 0..1 as bytes arrive, or with null while
  /// the server withholds a content length and there is no fraction to
  /// report. Throws [UpdateDownloadException] when the file cannot be
  /// fetched or written.
  Future<String> download(
    UpdateAsset asset, {
    void Function(double? progress)? onProgress,
  }) async {
    final folder = await downloadsDirectoryPath();
    if (folder == null) {
      throw const UpdateDownloadException('No Downloads folder on this device');
    }

    final request = http.Request('GET', Uri.parse(asset.downloadUrl));
    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(_timeout);
    } on TimeoutException {
      throw const UpdateDownloadException('GitHub took too long to answer');
    } on http.ClientException catch (e) {
      throw UpdateDownloadException(e.message);
    }

    if (response.statusCode != 200) {
      throw UpdateDownloadException('GitHub answered ${response.statusCode}');
    }

    // The release asset carries its own size, so a redirect that drops
    // Content-Length still leaves a total to divide by.
    final expected = response.contentLength ?? asset.sizeInBytes;
    final bytes = BytesBuilder(copy: false);
    try {
      await for (final chunk in response.stream.timeout(_timeout)) {
        bytes.add(chunk);
        onProgress?.call(expected > 0 ? bytes.length / expected : null);
      }
    } on TimeoutException {
      throw const UpdateDownloadException('The download stalled');
    } on http.ClientException catch (e) {
      throw UpdateDownloadException(e.message);
    }

    final path = '$folder${pathSeparator()}${asset.filename}';
    try {
      await writeBytes(path, bytes.takeBytes());
    } on Exception catch (e) {
      throw UpdateDownloadException('$e');
    }
    return path;
  }

  /// Opens the downloaded file's folder in the platform's file manager.
  Future<void> reveal(String path) => revealInFileManager(path);

  void dispose() {
    _client.close();
  }
}

/// A download that could not be fetched or written. [reason] is a
/// developer-facing detail; the card shows its own localised message.
class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.reason);

  final String reason;

  @override
  String toString() => 'UpdateDownloadException: $reason';
}
