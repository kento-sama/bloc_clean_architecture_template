import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/features/roles/domain/entities/role.dart';
import 'package:clean_bloc/features/roles/domain/repositories/role_repository.dart';
import 'package:clean_bloc/features/roles/domain/usecases/role_use_cases.dart';

class RoleCubit extends Cubit<LoadState<List<Role>>> {
  RoleCubit(this._repository) : super(const LoadState.loading()) {
    load();
  }

  final RoleRepository _repository;

  Future<void> load() async {
    emit(const LoadState.loading());
    try {
      emit(LoadState.success(await LoadRoles(_repository)()));
    } catch (error) {
      emit(LoadState.failure(error));
    }
  }

  Future<void> create(Map<String, Object?> values) async {
    await CreateRole(_repository)(values);
    await load();
  }

  Future<void> updateRole(String id, Map<String, Object?> values) async {
    await UpdateRole(_repository)(id, values);
    await load();
  }

  Future<void> grantPermissions(String id, List<String> permissions) async {
    await GrantRolePermissions(_repository)(id, permissions);
    await load();
  }

  Future<void> revokePermissions(String id, List<String> permissions) async {
    await RevokeRolePermissions(_repository)(id, permissions);
    await load();
  }

  Future<void> delete(String id) async {
    await DeleteRole(_repository)(id);
    await load();
  }
}
