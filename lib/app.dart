import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_bloc/core/routing/app_router.dart';
import 'package:clean_bloc/core/data/app_dependencies.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/users/presentation/cubits/user_cubit.dart';
import 'package:clean_bloc/features/roles/presentation/cubits/role_cubit.dart';
import 'package:clean_bloc/features/permissions/presentation/cubits/permission_cubit.dart';

import 'package:clean_bloc/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:clean_bloc/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:clean_bloc/features/users/data/datasources/user_remote_data_source.dart';
import 'package:clean_bloc/features/users/data/repositories/user_repository_impl.dart';
import 'package:clean_bloc/features/roles/data/datasources/role_remote_data_source.dart';
import 'package:clean_bloc/features/roles/data/repositories/role_repository_impl.dart';
import 'package:clean_bloc/features/permissions/data/datasources/permission_remote_data_source.dart';
import 'package:clean_bloc/features/permissions/data/repositories/permission_repository_impl.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // These fields create one long-lived instance of each shared Cubit. Recreating
  // them below would discard session/list state on every rebuild.
  final dependencies = AppDependencies();
  late final authCubit = AuthCubit(
    AuthRepositoryImpl(
      AuthRemoteDataSource(dependencies.dio),
      dependencies.tokenStorage,
    ),
  );
  late final userCubit = UserCubit(
    UserRepositoryImpl(UserRemoteDataSource(dependencies.dio)),
  );
  late final roleCubit = RoleCubit(
    RoleRepositoryImpl(RoleRemoteDataSource(dependencies.dio)),
  );
  late final permissionCubit = PermissionCubit(
    PermissionRepositoryImpl(PermissionRemoteDataSource(dependencies.dio)),
  );
  late final routerSetup = createAppRouter(authCubit);
  late final router = routerSetup.router;

  @override
  void dispose() {
    routerSetup.authSubscription.cancel();
    router.dispose();
    authCubit.close();
    userCubit.close();
    roleCubit.close();
    permissionCubit.close();

    dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider.value(value: userCubit),
        BlocProvider.value(value: roleCubit),
        BlocProvider.value(value: permissionCubit),
      ],
      child: MaterialApp.router(
        title: 'BLoC Clean Architecture Template',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3659D9)),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
