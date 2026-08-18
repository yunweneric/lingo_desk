import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Where an API key ended up being stored.
enum AiKeyStorage {
  /// The platform keychain / credential locker.
  secure,

  /// Local preferences, in plain text, because the keychain refused.
  ///
  /// On macOS the keychain needs a `keychain-access-groups` entitlement,
  /// which in turn needs a development signing certificate — an ad-hoc signed
  /// build gets `errSecMissingEntitlement` no matter what it asks for.
  fallback,
}

/// The API keys.
///
/// Tries the platform keychain first and falls back to preferences when the
/// platform refuses it, because losing the whole AI feature on an unsigned
/// build is worse than storing the key the same way every other setting in
/// this local-first app is stored. Which one happened is reported through
/// [storage] so the UI can say so plainly rather than implying a guarantee it
/// is not providing.
///
/// One key per provider, so switching providers in settings never discards
/// the key you already pasted for the other one.
class AiCredentialStore {
  AiCredentialStore({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences preferences,
  }) : _secure = secureStorage,
       _preferences = preferences;

  final FlutterSecureStorage _secure;
  final SharedPreferences _preferences;

  static const defaultSecureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AiKeyStorage _storage = AiKeyStorage.secure;

  /// Which backing store the last read or write actually used.
  AiKeyStorage get storage => _storage;

  Future<String?> read(String provider) async {
    final key = StorageKeys.aiApiKey(provider);
    try {
      final value = await _secure.read(key: key);
      if (value != null) {
        return value;
      }
    } on PlatformException {
      _storage = AiKeyStorage.fallback;
    } on MissingPluginException {
      _storage = AiKeyStorage.fallback;
    }
    // Either the keychain is unavailable, or it simply has nothing — a key
    // written during an earlier fallback run still has to come back.
    final stored = _preferences.getString(key);
    if (stored != null) {
      _storage = AiKeyStorage.fallback;
    }
    return stored;
  }

  Future<void> write(String provider, String apiKey) async {
    final key = StorageKeys.aiApiKey(provider);
    try {
      await _secure.write(key: key, value: apiKey);
      _storage = AiKeyStorage.secure;
      // Clear any copy an earlier fallback run left behind, so the plaintext
      // one does not outlive the keychain becoming available.
      await _preferences.remove(key);
      return;
    } on PlatformException {
      _storage = AiKeyStorage.fallback;
    } on MissingPluginException {
      _storage = AiKeyStorage.fallback;
    }
    await _preferences.setString(key, apiKey);
  }

  Future<void> delete(String provider) async {
    final key = StorageKeys.aiApiKey(provider);
    try {
      await _secure.delete(key: key);
    } on PlatformException {
      _storage = AiKeyStorage.fallback;
    } on MissingPluginException {
      _storage = AiKeyStorage.fallback;
    }
    await _preferences.remove(key);
  }
}
