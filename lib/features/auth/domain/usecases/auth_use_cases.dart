import 'package:clean_bloc/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_login_result.dart';
import 'package:clean_bloc/features/auth/domain/entities/two_factor_setup.dart';

// Keep session actions as small app-facing operations over the repository
// contract, without coupling presentation code to the HTTP implementation.
class RestoreSession {
  const RestoreSession(this._repository);
  final AuthRepository _repository;
  Future<AuthUser?> call() => _repository.currentUser();
}

class Login {
  const Login(this._repository);
  final AuthRepository _repository;
  Future<AuthLoginResult> call(String email, String password) =>
      _repository.login(email, password);
}

class CompleteTwoFactorLogin {
  const CompleteTwoFactorLogin(this._repository);
  final AuthRepository _repository;
  Future<AuthUser> call(String challengeToken, String code) =>
      _repository.completeTwoFactorLogin(challengeToken, code);
}

class Signup {
  const Signup(this._repository);
  final AuthRepository _repository;
  Future<AuthUser> call({
    required String name,
    required String email,
    required String password,
  }) => _repository.signup(name: name, email: email, password: password);
}

class Logout {
  const Logout(this._repository);
  final AuthRepository _repository;
  Future<void> call() => _repository.logout();
}

class BeginTwoFactorSetup {
  const BeginTwoFactorSetup(this._repository);
  final AuthRepository _repository;
  Future<TwoFactorSetup> call() => _repository.beginTwoFactorSetup();
}

class ConfirmTwoFactorSetup {
  const ConfirmTwoFactorSetup(this._repository);
  final AuthRepository _repository;
  Future<void> call(String code) => _repository.confirmTwoFactorSetup(code);
}

class DisableTwoFactor {
  const DisableTwoFactor(this._repository);
  final AuthRepository _repository;
  Future<void> call({required String password, required String code}) =>
      _repository.disableTwoFactor(password: password, code: code);
}

class DeleteAccount {
  const DeleteAccount(this._repository);
  final AuthRepository _repository;
  Future<void> call({required String password, String? code}) =>
      _repository.deleteAccount(password: password, code: code);
}
