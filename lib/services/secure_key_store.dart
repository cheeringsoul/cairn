import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around the OS keychain for API keys.
///
/// Keys are stored under `provider_api_key_<providerId>`. We never
/// write raw keys anywhere else — not SQLite, not SharedPreferences,
/// not logs. The provider_configs table only retains the last 4 digits
/// for UI display.
class SecureKeyStore {
  SecureKeyStore._();
  static final instance = SecureKeyStore._();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String _keyFor(String providerId) => 'provider_api_key_$providerId';

  Future<void> writeApiKey(String providerId, String key) =>
      _storage.write(key: _keyFor(providerId), value: key);

  Future<String?> readApiKey(String providerId) =>
      _storage.read(key: _keyFor(providerId));

  Future<void> deleteApiKey(String providerId) =>
      _storage.delete(key: _keyFor(providerId));
}
