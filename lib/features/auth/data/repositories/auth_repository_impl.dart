import 'package:dio/dio.dart';
import 'package:clean_bloc/core/data/token_storage.dart';
import 'package:clean_bloc/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:clean_bloc/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_login_result.dart';
import 'package:clean_bloc/features/auth/domain/entities/two_factor_setup.dart';

class AuthRepositoryImpl implements AuthRepository {
  // The repository implementation translates remote/network operations into
  // domain values and writes successful sessions to secure storage.
  const AuthRepositoryImpl(this._remote, this._tokens);
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<AuthUser?> currentUser() async {
    final accessToken = await _tokens.readAccessToken();
    final refreshToken = await _tokens.readRefreshToken();
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return null;
    }
    try {
      return await _remote.currentUser();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      // An expired token should send the user back to the sign-in screen.
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<AuthLoginResult> login(String email, String password) async {
    final result = await _remote.login(email, password);
    final session = result.session;
    if (session == null) {
      return AuthLoginResult.requiresTwoFactor(result.challengeToken!);
    }
    await _tokens.writeTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return AuthLoginResult.authenticated(session.user);
  }

  @override
  Future<AuthUser> completeTwoFactorLogin(
    String challengeToken,
    String code,
  ) async {
    final session = await _remote.completeTwoFactorLogin(challengeToken, code);
    await _tokens.writeTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session.user;
  }

  @override
  Future<AuthUser> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final session = await _remote.signup(
      name: name,
      email: email,
      password: password,
    );
    await _tokens.writeTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session.user;
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      // Clear locally even if the device is offline; propagate the API error.
      await _tokens.clear();
    }
  }

  @override
  Future<TwoFactorSetup> beginTwoFactorSetup() => _remote.beginTwoFactorSetup();

  @override
  Future<void> confirmTwoFactorSetup(String code) =>
      _remote.confirmTwoFactorSetup(code);

  @override
  Future<void> disableTwoFactor({
    required String password,
    required String code,
  }) => _remote.disableTwoFactor(password: password, code: code);

  @override
  Future<void> deleteAccount({required String password, String? code}) async {
    await _remote.deleteAccount(password: password, code: code);
    await _tokens.clear();
  }
}
