import 'package:dio/dio.dart';
import 'package:clean_bloc/core/config/api_endpoints.dart';
import 'package:clean_bloc/features/auth/data/models/auth_user_model.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';

/// Maps the Laravel authentication JSON contract into a domain user.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({String accessToken, String refreshToken, AuthUser user})> login(
    String email,
    String password,
  ) async {
    final response = await _dio.post<Object?>(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
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

  ({String accessToken, String refreshToken, AuthUser user}) _session(
    Object? response,
  ) {
    final body = _objectMap(response);
    // Laravel resources may wrap their result in a top-level "data" field.
    final data = body['data'] == null ? body : _objectMap(body['data']);
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
