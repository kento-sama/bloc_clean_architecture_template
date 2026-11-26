import 'package:dio/dio.dart';
import 'package:clean_bloc/core/data/token_storage.dart';
import 'package:clean_bloc/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:clean_bloc/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';

class AuthRepositoryImpl implements AuthRepository {
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
  Future<AuthUser> login(String email, String password) async {
    final session = await _remote.login(email, password);
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
}
