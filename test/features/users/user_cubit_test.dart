import 'package:flutter_test/flutter_test.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/domain/repositories/user_repository.dart';
import 'package:clean_bloc/features/users/presentation/cubits/user_cubit.dart';

void main() {
  test('load emits loading then success', () async {
    final cubit = UserCubit(_FakeUserRepository());

    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.value, hasLength(1));
    await cubit.close();
  });

  test('load emits failure when repository throws', () async {
    final cubit = UserCubit(_FakeUserRepository(error: StateError('failed')));

    await cubit.load();

    expect(cubit.state.status, LoadStatus.failure);
    await cubit.close();
  });

  test('create reloads the list after the mutation', () async {
    final repository = _FakeUserRepository();
    final cubit = UserCubit(repository);

    await cubit.create({'name': 'Ada', 'email': 'ada@example.com'});

    expect(repository.createCalls, 1);
    expect(cubit.state.status, LoadStatus.success);
    await cubit.close();
  });
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({this.error});

  final Object? error;
  int createCalls = 0;

  @override
  Future<List<User>> list() async {
    if (error != null) throw error!;
    return const [
      User(
        id: '1',
        name: 'Ada',
        email: 'ada@example.com',
        roles: [],
        directPermissions: [],
      ),
    ];
  }

  @override
  Future<void> create(Map<String, Object?> values) async {
    createCalls++;
  }

  @override
  Future<void> update(String id, Map<String, Object?> values) async {}

  @override
  Future<void> assignRoles(String id, List<String> roles) async {}

  @override
  Future<void> unassignRoles(String id, List<String> roles) async {}

  @override
  Future<void> grantPermissions(String id, List<String> permissions) async {}

  @override
  Future<void> revokePermissions(String id, List<String> permissions) async {}

  @override
  Future<void> delete(String id) async {}
}
