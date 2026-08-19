import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/localization/export.dart';

/// Local storage operations for app metadata.
///
/// Also exposes the per-app translation blob (read-only) so the
/// repository can compute dashboard stats.
abstract class AppLocalDataSource {
  Future<List<Map<String, dynamic>>> getApps();
  Future<Map<String, dynamic>?> getAppById(String id);
  Future<Map<String, dynamic>> createApp(Map<String, dynamic> app);
  Future<Map<String, dynamic>> updateApp(Map<String, dynamic> app);
  Future<void> deleteApp(String id);
  Future<Map<String, dynamic>?> getTranslationBlob(String appId);
}

class AppLocalDataSourceImpl implements AppLocalDataSource {
  const AppLocalDataSourceImpl({required this.preferences});

  final SharedPreferences preferences;

  @override
  Future<List<Map<String, dynamic>>> getApps() async {
    final raw = preferences.getString(StorageKeys.apps);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on FormatException catch (e) {
      throw CacheException(
        LocaleKeys.errorsAppListCorrupt.tr(namedArgs: {'error': e.message}),
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getAppById(String id) async {
    final apps = await getApps();
    for (final app in apps) {
      if (app['id'] == id) {
        return app;
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> createApp(Map<String, dynamic> app) async {
    final apps = await getApps();
    apps.add(app);
    await _saveApps(apps);
    return app;
  }

  @override
  Future<Map<String, dynamic>> updateApp(Map<String, dynamic> app) async {
    final apps = await getApps();
    final index = apps.indexWhere((item) => item['id'] == app['id']);
    if (index == -1) {
      throw CacheException(
        LocaleKeys.errorsAppNotFoundId.tr(
          namedArgs: {'id': '${app['id']}'},
        ),
      );
    }
    apps[index] = app;
    await _saveApps(apps);
    return app;
  }

  @override
  Future<void> deleteApp(String id) async {
    final apps = await getApps();
    apps.removeWhere((item) => item['id'] == id);
    await _saveApps(apps);
    // Remove the app's translations as well.
    await preferences.remove(StorageKeys.translations(id));
  }

  @override
  Future<Map<String, dynamic>?> getTranslationBlob(String appId) async {
    final raw = preferences.getString(StorageKeys.translations(appId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } on FormatException catch (e) {
      throw CacheException(
        LocaleKeys.errorsStoredTranslationsCorrupt.tr(
          namedArgs: {'error': e.message},
        ),
      );
    }
  }

  Future<void> _saveApps(List<Map<String, dynamic>> apps) async {
    final saved = await preferences.setString(
      StorageKeys.apps,
      jsonEncode(apps),
    );
    if (!saved) {
      throw CacheException(LocaleKeys.errorsWriteAppList.tr());
    }
  }
}
