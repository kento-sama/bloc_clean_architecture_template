import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_bloc/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_login_result.dart';
import 'package:clean_bloc/features/auth/domain/entities/two_factor_setup.dart';

class AuthCubit extends Cubit<LoadState<AuthUser?>> {
  // restore() begins immediately because the router needs a known session
  // before deciding whether to show protected or authentication routes.
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

  Future<AuthLoginResult> login(String email, String password) async {
    emit(const LoadState.loading());
    try {
      final result = await Login(_repository)(email, password);
      emit(LoadState.success(result.user));
      return result;
    } catch (error) {
      emit(LoadState.failure(error));
      rethrow;
    }
  }

  Future<void> completeTwoFactorLogin(
    String challengeToken,
    String code,
  ) async {
    emit(const LoadState.loading());
    try {
      emit(
        LoadState.success(
          await CompleteTwoFactorLogin(_repository)(challengeToken, code),
        ),
      );
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

  Future<TwoFactorSetup> beginTwoFactorSetup() =>
      BeginTwoFactorSetup(_repository)();

  Future<void> confirmTwoFactorSetup(String code) async {
    await ConfirmTwoFactorSetup(_repository)(code);
    emit(LoadState.success(await RestoreSession(_repository)()));
  }

  Future<void> disableTwoFactor({
    required String password,
    required String code,
  }) async {
    await DisableTwoFactor(_repository)(password: password, code: code);
    emit(LoadState.success(await RestoreSession(_repository)()));
  }

  Future<void> deleteAccount({required String password, String? code}) async {
    await DeleteAccount(_repository)(password: password, code: code);
    emit(const LoadState.success(null));
  }
}
