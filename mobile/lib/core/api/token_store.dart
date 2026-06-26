import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access + refresh tokens securely (Keychain/Keystore on
/// device; an encrypted store on web).
class TokenStore {
  TokenStore(this._storage);
  final FlutterSecureStorage _storage;

  static const _access = 'access_token';
  static const _refresh = 'refresh_token';

  String? accessToken;
  String? refreshToken;

  Future<void> load() async {
    accessToken = await _storage.read(key: _access);
    refreshToken = await _storage.read(key: _refresh);
  }

  Future<void> save({required String access, required String refresh}) async {
    accessToken = access;
    refreshToken = refresh;
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  Future<void> setAccess(String access) async {
    accessToken = access;
    await _storage.write(key: _access, value: access);
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }

  bool get hasSession => (refreshToken ?? '').isNotEmpty;
}
