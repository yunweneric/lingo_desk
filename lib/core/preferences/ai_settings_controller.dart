import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../features/ai_translation/domain/entities/ai_credentials.dart';
import '../../features/ai_translation/domain/entities/ai_key.dart';
import '../../features/ai_translation/domain/entities/ai_provider.dart';
import 'ai_credential_store.dart';
import 'app_preferences.dart';

/// The saved AI keys and which one translation runs use.
///
/// Metadata is a plain preference and the secrets come from the credential
/// store, which is async — so [load] runs once during bootstrap and
/// everything after that reads the in-memory list. That keeps call sites
/// synchronous, matching [AppSettingsController].
class AiSettingsController extends ChangeNotifier {
  AiSettingsController({
    required AppPreferences preferences,
    required AiCredentialStore credentialStore,
  }) : _preferences = preferences,
       _store = credentialStore;

  final AppPreferences _preferences;
  final AiCredentialStore _store;

  static const _uuid = Uuid();

  final List<AiKey> _keys = [];

  String? _activeKeyId;
  bool _loaded = false;
  String? _storageError;

  /// Every saved key, newest last.
  List<AiKey> get keys => List.unmodifiable(_keys);

  bool get isEmpty => _keys.isEmpty;

  /// The key translation runs use.
  AiKey? get activeKey {
    for (final key in _keys) {
      if (key.id == _activeKeyId) {
        return key;
      }
    }
    return _keys.isEmpty ? null : _keys.first;
  }

  String? get activeKeyId => activeKey?.id;

  AiCredentials get credentials =>
      activeKey?.credentials ??
      const AiCredentials(
        provider: AiProvider.anthropic,
        apiKey: '',
        model: '',
      );

  bool get isConfigured => activeKey?.isUsable ?? false;

  /// Why the keychain last refused a read or a write, or null when it is
  /// working. Surfaced in the UI instead of the app dying: a locked or
  /// unavailable keychain should cost you AI translation, not the whole
  /// workspace.
  String? get storageError => _storageError;

  AiKey? keyById(String id) {
    for (final key in _keys) {
      if (key.id == id) {
        return key;
      }
    }
    return null;
  }

  /// How many keys are saved for [provider].
  int countFor(AiProvider provider) =>
      _keys.where((key) => key.provider == provider).length;

  /// Reads the saved keys into memory. Safe to call more than once.
  ///
  /// Runs during bootstrap, so a keychain that is locked, unavailable, or
  /// simply absent must not stop the app from starting — it only means no
  /// key is configured yet.
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    _activeKeyId = _preferences.aiActiveKeyId;

    for (final raw in _preferences.aiKeys) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final id = json['id'] as String?;
        if (id == null) {
          continue;
        }
        final secret = await _read(id);
        _keys.add(AiKey.fromMetadataJson(json, secret ?? ''));
      } on FormatException {
        // A corrupted row should cost that row, not the whole list.
        continue;
      }
    }

    if (_keys.isEmpty) {
      await _migrateLegacyKeys();
    }
    notifyListeners();
  }

  /// Carries keys saved by the pre-list build (one slot per provider) into
  /// the list, so upgrading does not silently lose a pasted key.
  Future<void> _migrateLegacyKeys() async {
    final imported = <AiKey>[];
    for (final provider in AiProvider.values) {
      final secret = await _read(provider.id);
      if (secret == null || secret.trim().isEmpty) {
        continue;
      }
      final model = _preferences.legacyAiModel(provider.id)?.trim();
      imported.add(
        AiKey(
          id: _uuid.v4(),
          provider: provider,
          label: provider.label,
          apiKey: secret,
          model:
              (model == null || model.isEmpty) ? provider.defaultModel : model,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (imported.isEmpty) {
      return;
    }

    for (final key in imported) {
      _keys.add(key);
      await _write(key.id, key.apiKey);
    }

    // Keep whichever provider was active before the upgrade.
    final previous = _preferences.legacyAiProvider;
    final match = imported.where((key) => key.provider.id == previous);
    _activeKeyId = (match.isEmpty ? imported.first : match.first).id;

    await _persist();
    for (final provider in AiProvider.values) {
      await _delete(provider.id);
    }
    await _preferences.clearLegacyAiSettings([
      for (final provider in AiProvider.values) provider.id,
    ]);
  }

  Future<AiKey> addKey({
    required AiProvider provider,
    required String label,
    required String apiKey,
    required String model,
  }) async {
    final trimmedLabel = label.trim();
    final trimmedModel = model.trim();
    final key = AiKey(
      id: _uuid.v4(),
      provider: provider,
      label: trimmedLabel.isEmpty ? _defaultLabel(provider) : trimmedLabel,
      apiKey: apiKey.trim(),
      model: trimmedModel.isEmpty ? provider.defaultModel : trimmedModel,
      createdAt: DateTime.now(),
    );

    _keys.add(key);
    // The first key added is the one runs will use; later ones wait to be
    // chosen, so adding a second key never silently redirects spend.
    _activeKeyId ??= key.id;
    notifyListeners();

    await _write(key.id, key.apiKey);
    await _persist();
    return key;
  }

  Future<void> updateKey(
    String id, {
    String? label,
    String? apiKey,
    String? model,
  }) async {
    final index = _keys.indexWhere((key) => key.id == id);
    if (index == -1) {
      return;
    }
    final existing = _keys[index];
    final trimmedLabel = label?.trim();
    final trimmedModel = model?.trim();

    final updated = existing.copyWith(
      label:
          trimmedLabel == null
              ? null
              : (trimmedLabel.isEmpty
                  ? _defaultLabel(existing.provider)
                  : trimmedLabel),
      apiKey: apiKey?.trim(),
      model:
          trimmedModel == null
              ? null
              : (trimmedModel.isEmpty
                  ? existing.provider.defaultModel
                  : trimmedModel),
    );

    _keys[index] = updated;
    notifyListeners();

    if (updated.apiKey != existing.apiKey) {
      await _write(id, updated.apiKey);
    }
    await _persist();
  }

  Future<void> deleteKey(String id) async {
    final removed = _keys.indexWhere((key) => key.id == id);
    if (removed == -1) {
      return;
    }
    _keys.removeAt(removed);
    // Deleting the active key promotes another rather than leaving the app
    // configured-but-pointing-at-nothing.
    if (_activeKeyId == id) {
      _activeKeyId = _keys.isEmpty ? null : _keys.first.id;
    }
    notifyListeners();

    await _delete(id);
    await _persist();
  }

  Future<void> setActive(String id) async {
    if (_activeKeyId == id || keyById(id) == null) {
      return;
    }
    _activeKeyId = id;
    notifyListeners();
    await _preferences.setAiActiveKeyId(id);
  }

  String _defaultLabel(AiProvider provider) {
    final existing = countFor(provider);
    return existing == 0 ? provider.label : '${provider.label} ${existing + 1}';
  }

  Future<void> _persist() async {
    await _preferences.setAiKeys([
      for (final key in _keys) jsonEncode(key.toMetadataJson()),
    ]);
    await _preferences.setAiActiveKeyId(_activeKeyId);
  }

  Future<String?> _read(String id) async {
    try {
      return await _store.read(id);
    } on PlatformException catch (e) {
      _storageError = e.message ?? 'The system keychain is unavailable.';
    } on MissingPluginException {
      _storageError = 'Secure storage is unavailable on this platform.';
    }
    return null;
  }

  Future<void> _write(String id, String apiKey) =>
      _guardStorage(() => _store.write(id, apiKey));

  Future<void> _delete(String id) => _guardStorage(() => _store.delete(id));

  Future<void> _guardStorage(Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (e) {
      _storageError =
          'The key could not be saved to the system keychain '
          '(${e.message ?? e.code}). It will be forgotten when you quit.';
      notifyListeners();
    } on MissingPluginException {
      _storageError =
          'Secure storage is unavailable on this platform. The key will be '
          'forgotten when you quit.';
      notifyListeners();
    }
  }
}
