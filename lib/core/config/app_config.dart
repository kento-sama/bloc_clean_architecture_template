import 'package:envied/envied.dart';

part 'app_config.g.dart';

/// Reads API_BASE_URL from the root .env file during code generation.
@Envied(path: '.env')
abstract class AppConfig {
  @EnviedField(
    varName: 'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  )
  static const String baseUrl = _AppConfig.baseUrl;
}
