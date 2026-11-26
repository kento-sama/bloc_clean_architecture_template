import 'package:dio/dio.dart';
import 'package:clean_bloc/core/config/api_endpoints.dart';
import 'package:clean_bloc/core/data/token_storage.dart';

class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required this._dio,
    required this._refreshDio,
    required this._tokens,
  });

  static const _retryExtraKey = 'token_refresh_retry';
  static const _authorizationHeader = 'Authorization';

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStore _tokens;
  Future<String>? _refreshInProgress;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Login, signup, and refresh must work without an existing access token.
    if (_isAuthenticationEndpoint(options.uri.path)) {
      handler.next(options);
      return;
    }
    try {
      final accessToken = await _tokens.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers[_authorizationHeader] = 'Bearer $accessToken';
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    // Only recover a first 401 on a protected endpoint; this flag prevents an
    // unsuccessful retry from starting another refresh cycle.
    if (err.response?.statusCode != 401 ||
        request.extra[_retryExtraKey] == true ||
        _isAuthenticationEndpoint(request.uri.path)) {
      handler.next(err);
      return;
    }

    try {
      final refreshToken = await _tokens.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _tokens.clear();
        handler.next(err);
        return;
      }

      final currentAccessToken = await _tokens.readAccessToken();
      final failedAccessToken = _bearerToken(
        request.headers[_authorizationHeader],
      );
      // Another request may already have refreshed the session while this
      // request was waiting for its 401 handler.
      final accessToken =
          currentAccessToken != null &&
              currentAccessToken.isNotEmpty &&
              currentAccessToken != failedAccessToken
          ? currentAccessToken
          : await _refreshAccessToken();
      final response = await _retry(request, accessToken);
      handler.resolve(response);
    } on DioException catch (refreshError) {
      if (_isRefreshAuthorizationFailure(refreshError)) {
        try {
          await _tokens.clear();
        } catch (storageError, stackTrace) {
          handler.reject(
            DioException(
              requestOptions: request,
              error: storageError,
              stackTrace: stackTrace,
            ),
          );
          return;
        }
      }
      handler.reject(refreshError);
    } catch (cause, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: request,
          error: cause,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<String> _refreshAccessToken() async {
    final inProgress = _refreshInProgress;
    if (inProgress != null) return inProgress;

    // Concurrent 401s share one refresh request rather than rotating the same
    // refresh token multiple times.
    final refreshFuture = _performRefresh();
    _refreshInProgress = refreshFuture;
    try {
      return await refreshFuture;
    } finally {
      _refreshInProgress = null;
    }
  }

  Future<String> _performRefresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('A refresh token is required to refresh the session.');
    }

    final response = await _refreshDio.post<Object?>(
      ApiEndpoints.authRefresh,
      data: {ApiEndpoints.refreshTokenField: refreshToken},
    );
    final data = _responseData(response.data);
    final accessToken = data['access_token'];
    final rotatedRefreshToken = data['refresh_token'];
    // The API rotates both tokens, so reject incomplete responses before
    // writing anything to secure storage.
    if (accessToken is! String ||
        accessToken.isEmpty ||
        rotatedRefreshToken is! String ||
        rotatedRefreshToken.isEmpty) {
      throw const FormatException(
        'The refresh API must return non-empty access_token and refresh_token values.',
      );
    }

    // Do not overwrite credentials if the user signed out or changed sessions
    // while the network request was in flight.
    if (await _tokens.readRefreshToken() != refreshToken) {
      throw StateError('The session changed while its tokens were refreshing.');
    }
    await _tokens.writeTokens(
      accessToken: accessToken,
      refreshToken: rotatedRefreshToken,
    );
    return accessToken;
  }

  Future<Response<dynamic>> _retry(RequestOptions request, String accessToken) {
    // Reuse the original request (method, body, and options) with the new token.
    request.extra[_retryExtraKey] = true;
    request.headers[_authorizationHeader] = 'Bearer $accessToken';
    return _dio.fetch<dynamic>(request);
  }

  Map<String, Object?> _responseData(Object? response) {
    if (response is! Map) {
      throw const FormatException(
        'The refresh API returned an invalid response.',
      );
    }
    final payload = response['data'] ?? response;
    if (payload is Map) return Map<String, Object?>.from(payload);
    throw const FormatException(
      'The refresh API returned an invalid response.',
    );
  }

  String? _bearerToken(Object? authorization) {
    if (authorization is! String || !authorization.startsWith('Bearer ')) {
      return null;
    }
    return authorization.substring('Bearer '.length);
  }

  bool _isAuthenticationEndpoint(String path) =>
      path.endsWith(ApiEndpoints.authLogin) ||
      path.endsWith(ApiEndpoints.authRegister) ||
      path.endsWith(ApiEndpoints.authRefresh);

  bool _isRefreshAuthorizationFailure(DioException error) {
    final status = error.response?.statusCode;
    return status == 401 || status == 403;
  }
}
