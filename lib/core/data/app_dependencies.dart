import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:clean_bloc/core/config/app_config.dart';
import 'package:clean_bloc/core/data/token_refresh_interceptor.dart';
import 'package:clean_bloc/core/data/token_storage.dart';

class AppDependencies {
  AppDependencies()
    : tokenStorage = const TokenStorage(FlutterSecureStorage()) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: const {'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
      ),
    );
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        headers: const {'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
      ),
    );
    dio.interceptors.add(
      TokenRefreshInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        tokens: tokenStorage,
      ),
    );
  }

  final TokenStorage tokenStorage;
  late final Dio dio;

  void dispose() {
    dio.close(force: true);
  }
}
