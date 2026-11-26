import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clean_bloc/core/config/api_endpoints.dart';
import 'package:clean_bloc/core/data/token_refresh_interceptor.dart';
import 'package:clean_bloc/core/data/token_storage.dart';

void main() {
  // The fake server makes refresh/retry ordering observable without relying
  // on a real Laravel instance or network credentials.
  late HttpServer server;
  late Dio dio;
  late Dio refreshDio;
  late _MemoryTokenStore tokens;
  late int refreshRequests;
  late int protectedRequests;
  late String? refreshRequestBody;

  Future<void> startServer({
    required int initialRequestCount,
    required bool rejectFreshAccessToken,
  }) async {
    // Hold refresh responses until every initial protected request has failed,
    // creating the concurrent-401 case deterministically.
    final initialRequestsReceived = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == ApiEndpoints.authRefresh) {
        refreshRequests++;
        refreshRequestBody = await utf8.decoder.bind(request).join();
        await initialRequestsReceived.future.timeout(
          const Duration(seconds: 5),
        );
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          jsonEncode({
            'data': {
              'access_token': 'fresh-access-token',
              'refresh_token': 'rotated-refresh-token',
            },
          }),
        );
      } else if (request.uri.path == '/protected') {
        protectedRequests++;
        if (protectedRequests == initialRequestCount) {
          initialRequestsReceived.complete();
        }
        final hasFreshToken =
            request.headers.value(HttpHeaders.authorizationHeader) ==
            'Bearer fresh-access-token';
        final authorized = hasFreshToken && !rejectFreshAccessToken;
        request.response.statusCode = authorized
            ? HttpStatus.ok
            : HttpStatus.unauthorized;
        request.response.write(jsonEncode({'authorized': authorized}));
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    final baseUrl = 'http://127.0.0.1:${server.port}';
    dio = Dio(BaseOptions(baseUrl: baseUrl));
    refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
    dio.interceptors.add(
      TokenRefreshInterceptor(dio: dio, refreshDio: refreshDio, tokens: tokens),
    );
  }

  setUp(() {
    tokens = _MemoryTokenStore(
      accessToken: 'expired-access-token',
      refreshToken: 'existing-refresh-token',
    );
    refreshRequests = 0;
    protectedRequests = 0;
    refreshRequestBody = null;
  });

  tearDown(() async {
    dio.close(force: true);
    refreshDio.close(force: true);
    await server.close(force: true);
  });

  test('refreshes once for concurrent 401s and retries each request', () async {
    await startServer(initialRequestCount: 2, rejectFreshAccessToken: false);

    final responses = await Future.wait([
      dio.get<Object?>('/protected'),
      dio.get<Object?>('/protected'),
    ]);

    expect(responses, hasLength(2));
    expect(refreshRequests, 1);
    expect(protectedRequests, 4);
    expect(
      jsonDecode(refreshRequestBody!)['refresh_token'],
      'existing-refresh-token',
    );
    expect(await tokens.readAccessToken(), 'fresh-access-token');
    expect(await tokens.readRefreshToken(), 'rotated-refresh-token');
  });

  test(
    'does not refresh again when the retried request is still unauthorized',
    () async {
      await startServer(initialRequestCount: 1, rejectFreshAccessToken: true);

      await expectLater(
        dio.get<Object?>('/protected'),
        throwsA(isA<DioException>()),
      );

      expect(refreshRequests, 1);
      expect(protectedRequests, 2);
      expect(await tokens.readAccessToken(), isNull);
      expect(await tokens.readRefreshToken(), isNull);
    },
  );
}

class _MemoryTokenStore implements TokenStore {
  // In-memory replacement for secure storage keeps the test isolated.
  _MemoryTokenStore({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}
