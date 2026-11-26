import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_bloc/features/auth/domain/usecases/auth_use_cases.dart';

class AuthCubit extends Cubit<LoadState<AuthUser?>> {
  AuthCubit(this._repository) : super(const LoadState.loading()) {
    restore();
  }

  final AuthRepository _repository;

  Future<void> restore() async {
    emit(const LoadState.loading());
    try {
      emit(LoadState.success(await RestoreSession(_repository)()));
    } catch (error) {
      emit(LoadState.success(null));
    }
  }

  Future<void> login(String email, String password) async {
    emit(const LoadState.loading());
    try {
      emit(LoadState.success(await Login(_repository)(email, password)));
    } catch (error) {
      emit(LoadState.failure(error));
      rethrow;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const LoadState.loading());
    try {
      emit(
        LoadState.success(
          await Signup(_repository)(
            name: name,
            email: email,
            password: password,
          ),
        ),
      );
    } catch (error) {
      emit(LoadState.failure(error));
      rethrow;
    }
  }

  Future<void> logout() async {
    await Logout(_repository)();
    emit(const LoadState.success(null));
  }
}
