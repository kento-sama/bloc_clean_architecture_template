import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Defines the token operations used by auth and HTTP code.
abstract interface class TokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

/// Keeps access and refresh tokens out of ordinary preferences.
class TokenStorage implements TokenStore {
  const TokenStorage(this._storage);
  static const _accessTokenKey = 'laravel_api_token';
  static const _refreshTokenKey = 'laravel_api_refresh_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      // Treat the pair as one logical session: a partial write must not leave
      // credentials that can no longer be refreshed reliably.
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
    } catch (_) {
      await clear();
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
