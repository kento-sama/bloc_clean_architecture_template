import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/features/permissions/domain/entities/permission.dart';
import 'package:clean_bloc/features/permissions/domain/repositories/permission_repository.dart';
import 'package:clean_bloc/features/permissions/domain/usecases/permission_use_cases.dart';

class PermissionCubit extends Cubit<LoadState<List<Permission>>> {
  PermissionCubit(this._repository) : super(const LoadState.loading()) {
    load();
  }

  final PermissionRepository _repository;

  Future<void> load() async {
    emit(const LoadState.loading());
    try {
      emit(LoadState.success(await LoadPermissions(_repository)()));
    } catch (error) {
      emit(LoadState.failure(error));
    }
  }

  Future<void> create(Map<String, Object?> values) async {
    await CreatePermissionUseCase(_repository)(values);
    await load();
  }

  Future<void> updatePermission(String id, Map<String, Object?> values) async {
    await UpdatePermissionUseCase(_repository)(id, values);
    await load();
  }

  Future<void> delete(String id) async {
    await DeletePermissionUseCase(_repository)(id);
    await load();
  }
}
