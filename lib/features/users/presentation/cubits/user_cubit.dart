import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/domain/repositories/user_repository.dart';
import 'package:clean_bloc/features/users/domain/usecases/user_use_cases.dart';

class UserCubit extends Cubit<LoadState<List<User>>> {
  UserCubit(this._repository) : super(const LoadState.loading()) {
    load();
  }

  final UserRepository _repository;

  Future<void> load() async {
    emit(const LoadState.loading());
    try {
      emit(LoadState.success(await LoadUsers(_repository)()));
    } catch (error) {
      emit(LoadState.failure(error));
    }
  }

  Future<void> create(Map<String, Object?> values) async {
    await CreateUser(_repository)(values);
    await load();
  }

  Future<void> updateUser(String id, Map<String, Object?> values) async {
    await UpdateUser(_repository)(id, values);
    await load();
  }

  Future<void> assignRoles(String id, List<String> roles) async {
    await AssignUserRoles(_repository)(id, roles);
    await load();
  }

  Future<void> unassignRoles(String id, List<String> roles) async {
    await UnassignUserRoles(_repository)(id, roles);
    await load();
  }

  Future<void> grantPermissions(String id, List<String> permissions) async {
    await GrantUserPermissions(_repository)(id, permissions);
    await load();
  }

  Future<void> revokePermissions(String id, List<String> permissions) async {
    await RevokeUserPermissions(_repository)(id, permissions);
    await load();
  }

  Future<void> delete(String id) async {
    await DeleteUser(_repository)(id);
    await load();
  }
}
