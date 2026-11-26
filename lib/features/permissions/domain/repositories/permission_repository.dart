import 'package:clean_bloc/features/permissions/domain/entities/permission.dart';

abstract interface class PermissionRepository {
  Future<List<Permission>> list();
  Future<void> create(Map<String, Object?> values);
  Future<void> update(String id, Map<String, Object?> values);
  Future<void> delete(String id);
}
