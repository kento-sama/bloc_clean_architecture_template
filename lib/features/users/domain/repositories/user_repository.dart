import 'package:clean_bloc/features/users/domain/entities/user.dart';

abstract interface class UserRepository {
  Future<List<User>> list();
  Future<void> create(Map<String, Object?> values);
  Future<void> update(String id, Map<String, Object?> values);
  Future<void> assignRoles(String id, List<String> roles);
  Future<void> unassignRoles(String id, List<String> roles);
  Future<void> grantPermissions(String id, List<String> permissions);
  Future<void> revokePermissions(String id, List<String> permissions);
  Future<void> delete(String id);
}
