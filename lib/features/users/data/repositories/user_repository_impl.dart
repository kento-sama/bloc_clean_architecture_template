import 'package:clean_bloc/features/users/data/datasources/user_remote_data_source.dart';
import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._remote);
  final UserRemoteDataSource _remote;

  @override
  Future<List<User>> list() => _remote.list();
  @override
  Future<void> create(Map<String, Object?> values) => _remote.create(values);
  @override
  Future<void> update(String id, Map<String, Object?> values) =>
      _remote.update(id, values);
  @override
  Future<void> assignRoles(String id, List<String> roles) =>
      _remote.assignRoles(id, roles);
  @override
  Future<void> unassignRoles(String id, List<String> roles) =>
      _remote.unassignRoles(id, roles);
  @override
  Future<void> grantPermissions(String id, List<String> permissions) =>
      _remote.grantPermissions(id, permissions);
  @override
  Future<void> revokePermissions(String id, List<String> permissions) =>
      _remote.revokePermissions(id, permissions);
  @override
  Future<void> delete(String id) => _remote.delete(id);
}
