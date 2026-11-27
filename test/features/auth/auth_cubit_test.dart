import 'package:flutter_test/flutter_test.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_login_result.dart';
import 'package:clean_bloc/features/auth/domain/entities/two_factor_setup.dart';
import 'package:clean_bloc/features/auth/domain/repositories/auth_repository.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';

void main() {
  test('login emits loading then success', () async {
    final repository = _FakeAuthRepository();
    final cubit = AuthCubit(repository);
    await cubit.login('user@example.com', 'password');

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.value?.email, 'user@example.com');
    await cubit.close();
  });

  test('login emits failure and rethrows on repository error', () async {
    final repository = _FakeAuthRepository(
      loginError: StateError('login failed'),
    );
    final cubit = AuthCubit(repository);

    await expectLater(
      cubit.login('user@example.com', 'password'),
      throwsStateError,
    );
    expect(cubit.state.status, LoadStatus.failure);
    await cubit.close();
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.loginError});

  final Object? loginError;

  @override
  Future<AuthUser?> currentUser() async => null;

  @override
  Future<AuthLoginResult> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    return AuthLoginResult.authenticated(
      AuthUser(
        id: '1',
        name: 'Test User',
        email: email,
        permissions: const {},
        roles: const {},
      ),
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> signup({
    required String name,
    required String email,
    required String password,
  }) async => AuthUser(
    id: '1',
    name: name,
    email: email,
    permissions: const {},
    roles: const {},
  );

  @override
  Future<AuthUser> completeTwoFactorLogin(
    String challengeToken,
    String code,
  ) async => AuthUser(
    id: '1',
    name: 'Test User',
    email: 'user@example.com',
    permissions: const {},
    roles: const {},
  );

  @override
  Future<TwoFactorSetup> beginTwoFactorSetup() async =>
      const TwoFactorSetup(secret: 'SECRET', provisioningUri: 'otpauth://totp');

  @override
  Future<void> confirmTwoFactorSetup(String code) async {}

  @override
  Future<void> disableTwoFactor({
    required String password,
    required String code,
  }) async {}

  @override
  Future<void> deleteAccount({required String password, String? code}) async {}
}
