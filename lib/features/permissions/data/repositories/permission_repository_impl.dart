import 'package:clean_bloc/features/permissions/data/datasources/permission_remote_data_source.dart';
import 'package:clean_bloc/features/permissions/domain/entities/permission.dart';
import 'package:clean_bloc/features/permissions/domain/repositories/permission_repository.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  const PermissionRepositoryImpl(this._remote);
  final PermissionRemoteDataSource _remote;
  @override
  Future<List<Permission>> list() => _remote.list();
  @override
  Future<void> create(Map<String, Object?> values) => _remote.create(values);
  @override
  Future<void> update(String id, Map<String, Object?> values) =>
      _remote.update(id, values);
  @override
  Future<void> delete(String id) => _remote.delete(id);
}
