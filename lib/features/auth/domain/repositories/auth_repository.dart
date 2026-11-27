import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_login_result.dart';
import 'package:clean_bloc/features/auth/domain/entities/two_factor_setup.dart';

/// Authentication boundary used by the app layer.
abstract interface class AuthRepository {
  // The repository contract separates Cubits/use cases from Dio and Laravel.
  Future<AuthUser?> currentUser();
  Future<AuthLoginResult> login(String email, String password);
  Future<AuthUser> completeTwoFactorLogin(String challengeToken, String code);
  Future<AuthUser> signup({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<TwoFactorSetup> beginTwoFactorSetup();
  Future<void> confirmTwoFactorSetup(String code);
  Future<void> disableTwoFactor({
    required String password,
    required String code,
  });
  Future<void> deleteAccount({required String password, String? code});
}
