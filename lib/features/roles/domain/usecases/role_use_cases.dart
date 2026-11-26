import 'package:clean_bloc/features/roles/domain/entities/role.dart';
import 'package:clean_bloc/features/roles/domain/repositories/role_repository.dart';

class LoadRoles {
  const LoadRoles(this._repository);
  final RoleRepository _repository;
  Future<List<Role>> call() => _repository.list();
}

class CreateRole {
  const CreateRole(this._repository);
  final RoleRepository _repository;
  Future<void> call(Map<String, Object?> values) => _repository.create(values);
}

class UpdateRole {
  const UpdateRole(this._repository);
  final RoleRepository _repository;
  Future<void> call(String id, Map<String, Object?> values) =>
      _repository.update(id, values);
}

class DeleteRole {
  const DeleteRole(this._repository);
  final RoleRepository _repository;
  Future<void> call(String id) => _repository.delete(id);
}

class GrantRolePermissions {
  const GrantRolePermissions(this._repository);
  final RoleRepository _repository;
  Future<void> call(String id, List<String> permissions) =>
      _repository.grantPermissions(id, permissions);
}

class RevokeRolePermissions {
  const RevokeRolePermissions(this._repository);
  final RoleRepository _repository;
  Future<void> call(String id, List<String> permissions) =>
      _repository.revokePermissions(id, permissions);
}
