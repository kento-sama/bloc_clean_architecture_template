import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';

/// Authentication boundary used by the app layer.
abstract interface class AuthRepository {
  Future<AuthUser?> currentUser();
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> signup({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
}
