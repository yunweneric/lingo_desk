import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'github_release.dart';

/// Reads the public GitHub REST API for the two things the landing page
/// needs: the newest release and the repository's star count.
///
/// Both endpoints are unauthenticated and CORS-enabled, which is why the
/// download button resolves *releases* rather than Actions artifacts —
/// artifact downloads require a token no public page can carry.
class GithubService {
  GithubService({http.Client? client, this.apiBase = GithubRepo.api})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Overridable so the resolved-release UI can be exercised against a
  /// repository that already publishes builds.
  final String apiBase;

  static const _timeout = Duration(seconds: 8);
  static const _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  ReleaseState? _cachedRelease;
  int? _cachedStars;

  /// The newest published release, or the state explaining why there
  /// isn't one. Cached for the session — the page asks on first paint and
  /// again whenever a visitor retries.
  Future<ReleaseState> latestRelease({bool refresh = false}) async {
    final cached = _cachedRelease;
    if (cached != null && !refresh) {
      return cached;
    }

    final state = await _fetchLatestRelease();
    // Never cache a transient failure: a visitor who reconnects and hits
    // retry should get a real request.
    if (state is! ReleaseUnavailable) {
      _cachedRelease = state;
    }
    return state;
  }

  Future<ReleaseState> _fetchLatestRelease() async {
    try {
      final response = await _client
          .get(Uri.parse('$apiBase/releases/latest'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return const ReleasePending();
      }
      if (response.statusCode == 403 || response.statusCode == 429) {
        return const ReleaseUnavailable(
          'GitHub is rate limiting this browser.',
        );
      }
      if (response.statusCode != 200) {
        return ReleaseUnavailable(
          'GitHub answered with ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const ReleaseUnavailable('GitHub returned an unexpected reply.');
      }

      final release = GithubRelease.fromJson(decoded);
      // A tag whose build jobs failed still creates a release, just an
      // empty one. That is the same story as having no release at all.
      return release.hasDownloads
          ? ReleaseReady(release)
          : const ReleasePending();
    } on TimeoutException {
      return const ReleaseUnavailable('GitHub took too long to answer.');
    } on http.ClientException {
      return const ReleaseUnavailable('Could not reach GitHub.');
    } on FormatException {
      return const ReleaseUnavailable('GitHub returned an unexpected reply.');
    }
  }

  /// Star count for the open-source section. Best effort: any failure
  /// simply hides the badge.
  Future<int?> stars() async {
    final cached = _cachedStars;
    if (cached != null) {
      return cached;
    }
    try {
      final response = await _client
          .get(Uri.parse(apiBase), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final count = (decoded['stargazers_count'] as num?)?.toInt();
      _cachedStars = count;
      return count;
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
