import 'package:clean_bloc/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';

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
  Future<AuthUser> call(String email, String password) =>
      _repository.login(email, password);
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
