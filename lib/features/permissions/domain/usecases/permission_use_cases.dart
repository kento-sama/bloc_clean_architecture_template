import 'package:clean_bloc/features/permissions/domain/entities/permission.dart';
import 'package:clean_bloc/features/permissions/domain/repositories/permission_repository.dart';

class LoadPermissions {
  const LoadPermissions(this._repository);
  final PermissionRepository _repository;
  Future<List<Permission>> call() => _repository.list();
}

class CreatePermissionUseCase {
  const CreatePermissionUseCase(this._repository);
  final PermissionRepository _repository;
  Future<void> call(Map<String, Object?> values) => _repository.create(values);
}

class UpdatePermissionUseCase {
  const UpdatePermissionUseCase(this._repository);
  final PermissionRepository _repository;
  Future<void> call(String id, Map<String, Object?> values) =>
      _repository.update(id, values);
}

class DeletePermissionUseCase {
  const DeletePermissionUseCase(this._repository);
  final PermissionRepository _repository;
  Future<void> call(String id) => _repository.delete(id);
}
