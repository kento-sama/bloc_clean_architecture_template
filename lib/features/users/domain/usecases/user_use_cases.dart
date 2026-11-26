import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/domain/repositories/user_repository.dart';

class LoadUsers {
  const LoadUsers(this._repository);
  final UserRepository _repository;
  Future<List<User>> call() => _repository.list();
}

class CreateUser {
  const CreateUser(this._repository);
  final UserRepository _repository;
  Future<void> call(Map<String, Object?> values) => _repository.create(values);
}

class UpdateUser {
  const UpdateUser(this._repository);
  final UserRepository _repository;
  Future<void> call(String id, Map<String, Object?> values) =>
      _repository.update(id, values);
}

class DeleteUser {
  const DeleteUser(this._repository);
  final UserRepository _repository;
  Future<void> call(String id) => _repository.delete(id);
}

class AssignUserRoles {
  const AssignUserRoles(this._repository);
  final UserRepository _repository;
  Future<void> call(String id, List<String> roles) =>
      _repository.assignRoles(id, roles);
}

class UnassignUserRoles {
  const UnassignUserRoles(this._repository);
  final UserRepository _repository;
  Future<void> call(String id, List<String> roles) =>
      _repository.unassignRoles(id, roles);
}

class GrantUserPermissions {
  const GrantUserPermissions(this._repository);
  final UserRepository _repository;
  Future<void> call(String id, List<String> permissions) =>
      _repository.grantPermissions(id, permissions);
}

class RevokeUserPermissions {
  const RevokeUserPermissions(this._repository);
  final UserRepository _repository;
  Future<void> call(String id, List<String> permissions) =>
      _repository.revokePermissions(id, permissions);
}
