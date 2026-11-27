import 'package:dio/dio.dart';
import 'package:clean_bloc/core/config/api_endpoints.dart';
import 'package:clean_bloc/features/auth/data/models/auth_user_model.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/domain/entities/two_factor_setup.dart';
import 'package:clean_bloc/features/auth/data/models/two_factor_setup_model.dart';

/// Maps the Laravel authentication JSON contract into a domain user.
class AuthRemoteDataSource {
  // This data source owns HTTP requests and maps Laravel JSON envelopes.
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<
    ({
      ({String accessToken, String refreshToken, AuthUser user})? session,
      String? challengeToken,
    })
  >
  login(String email, String password) async {
    final response = await _dio.post<Object?>(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    final body = _unwrap(response.data);
    final challengeToken = body['challenge_token'];
    if (body['two_factor_required'] == true || challengeToken != null) {
      if (challengeToken is! String || challengeToken.isEmpty) {
        throw const FormatException(
          'The two-factor login response must include a challenge_token.',
        );
      }
      return (session: null, challengeToken: challengeToken);
    }
    return (session: _session(body), challengeToken: null);
  }

  Future<({String accessToken, String refreshToken, AuthUser user})>
  completeTwoFactorLogin(String challengeToken, String code) async {
    final response = await _dio.post<Object?>(
      ApiEndpoints.authTwoFactorChallenge,
      data: {'challenge_token': challengeToken, 'code': code},
    );
    return _session(response.data);
  }

  Future<({String accessToken, String refreshToken, AuthUser user})> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      ApiEndpoints.authRegister,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
    return _session(response.data);
  }

  Future<AuthUser> currentUser() async {
    final response = await _dio.get<Object?>(ApiEndpoints.authCurrentUser);
    final body = _objectMap(response.data);
    final user = body['data'] ?? response.data;
    return _user(_objectMap(user));
  }

  Future<void> logout() async {
    await _dio.post<Object?>(ApiEndpoints.authLogout);
  }

  Future<TwoFactorSetup> beginTwoFactorSetup() async {
    final response = await _dio.post<Object?>(ApiEndpoints.authTwoFactorSetup);
    return TwoFactorSetupModel.fromJson(_unwrap(response.data));
  }

  Future<void> confirmTwoFactorSetup(String code) async {
    await _dio.post<Object?>(
      ApiEndpoints.authTwoFactorConfirm,
      data: {'code': code},
    );
  }

  Future<void> disableTwoFactor({
    required String password,
    required String code,
  }) async {
    await _dio.delete<Object?>(
      ApiEndpoints.authTwoFactor,
      data: {'password': password, 'code': code},
    );
  }

  Future<void> deleteAccount({required String password, String? code}) async {
    await _dio.delete<Object?>(
      ApiEndpoints.authCurrentUser,
      data: {'password': password, 'code': ?code},
    );
  }

  Map<String, Object?> _unwrap(Object? response) {
    final body = _objectMap(response);
    return body['data'] == null ? body : _objectMap(body['data']);
  }

  ({String accessToken, String refreshToken, AuthUser user}) _session(
    Object? response,
  ) {
    final data = _unwrap(response);
    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const FormatException(
        'Laravel login/register must return non-empty access_token and refresh_token values.',
      );
    }
    return (
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: _user(_objectMap(data['user'])),
    );
  }

  AuthUser _user(Map<String, Object?> json) => AuthUserModel.fromJson(json);

  Map<String, Object?> _objectMap(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException(
      'The Laravel API returned an invalid response.',
    );
  }
}
