import 'package:clean_bloc/features/roles/data/datasources/role_remote_data_source.dart';
import 'package:clean_bloc/features/roles/domain/entities/role.dart';
import 'package:clean_bloc/features/roles/domain/repositories/role_repository.dart';

class RoleRepositoryImpl implements RoleRepository {
  const RoleRepositoryImpl(this._remote);
  final RoleRemoteDataSource _remote;
  @override
  Future<List<Role>> list() => _remote.list();
  @override
  Future<void> create(Map<String, Object?> values) => _remote.create(values);
  @override
  Future<void> update(String id, Map<String, Object?> values) =>
      _remote.update(id, values);
  @override
  Future<void> grantPermissions(String id, List<String> permissions) =>
      _remote.grantPermissions(id, permissions);
  @override
  Future<void> revokePermissions(String id, List<String> permissions) =>
      _remote.revokePermissions(id, permissions);
  @override
  Future<void> delete(String id) => _remote.delete(id);
}
