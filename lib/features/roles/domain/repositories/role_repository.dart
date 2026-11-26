import 'package:clean_bloc/features/roles/domain/entities/role.dart';

abstract interface class RoleRepository {
  Future<List<Role>> list();
  Future<void> create(Map<String, Object?> values);
  Future<void> update(String id, Map<String, Object?> values);
  Future<void> grantPermissions(String id, List<String> permissions);
  Future<void> revokePermissions(String id, List<String> permissions);
  Future<void> delete(String id);
}
