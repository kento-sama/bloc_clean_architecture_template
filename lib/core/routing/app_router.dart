import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/app_modules.dart';
import 'package:clean_bloc/core/presentation/bloc_states.dart';
import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';
import 'package:clean_bloc/features/auth/presentation/screens/auth_page.dart';
import 'package:clean_bloc/features/auth/presentation/screens/account_page.dart';
import 'package:clean_bloc/features/auth/presentation/screens/account_security_page.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/dashboard/presentation/screens/dashboard_page.dart';
import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/presentation/screens/user_form_page.dart';
import 'package:clean_bloc/features/users/user_config.dart';
import 'package:clean_bloc/features/roles/domain/entities/role.dart';
import 'package:clean_bloc/features/roles/presentation/screens/role_form_page.dart';
import 'package:clean_bloc/features/roles/role_config.dart';
import 'package:clean_bloc/features/permissions/domain/entities/permission.dart';
import 'package:clean_bloc/features/permissions/presentation/screens/permission_form_page.dart';
import 'package:clean_bloc/features/permissions/permission_config.dart';

({GoRouter router, StreamSubscription<LoadState<AuthUser?>> authSubscription})
createAppRouter(AuthCubit authCubit) {
  late final GoRouter router;
  router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // Guard the route graph with auth state and effective permissions.
      // Laravel remains the authoritative server-side authorization boundary.
      final auth = authCubit.state;
      final user = auth.value;
      final path = state.matchedLocation;
      final isAuthPage = path == '/login' || path == '/signup';
      if (auth.isLoading) return null;
      if (user == null) return isAuthPage ? null : '/login';
      if (isAuthPage || path == '/loading') return '/dashboard';

      final requiredPermission = appModules
          .where(
            (feature) =>
                path == feature.path || path.startsWith('${feature.path}/'),
          )
          .firstOrNull
          ?.viewPermission;
      if (requiredPermission != null && !user.canAccess(requiredPermission)) {
        return '/forbidden';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/loading', builder: (_, _) => const LoadingPage()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const AuthPage(isSignup: false),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const AuthPage(isSignup: true),
      ),
      GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),
      GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
      GoRoute(
        path: '/account/security',
        builder: (_, _) => const AccountSecurityPage(),
      ),
      for (final feature in appModules)
        GoRoute(path: feature.path, builder: (_, _) => feature.pageBuilder()),
      GoRoute(
        path: '$userPath/create',
        redirect: (_, _) {
          if (authCubit.state.isLoading) return null;
          return authCubit.state.value?.canAccess(userCreatePermission) == true
              ? null
              : '/forbidden';
        },
        builder: (_, _) => const UserFormPage(),
      ),
      GoRoute(
        path: '$userPath/:id/edit',
        redirect: (_, state) {
          if (authCubit.state.isLoading) return null;
          if (state.extra is! User) return userPath;
          return authCubit.state.value?.canAccess(userUpdatePermission) == true
              ? null
              : '/forbidden';
        },
        builder: (_, state) => UserFormPage(
          user: state.extra is User ? state.extra as User : null,
        ),
      ),
      GoRoute(
        path: '$rolePath/create',
        redirect: (_, _) {
          if (authCubit.state.isLoading) return null;
          return authCubit.state.value?.canAccess(roleCreatePermission) == true
              ? null
              : '/forbidden';
        },
        builder: (_, _) => const RoleFormPage(),
      ),
      GoRoute(
        path: '$rolePath/:id/edit',
        redirect: (_, state) {
          if (authCubit.state.isLoading) return null;
          if (state.extra is! Role) return rolePath;
          return authCubit.state.value?.canAccess(roleUpdatePermission) == true
              ? null
              : '/forbidden';
        },
        builder: (_, state) => RoleFormPage(
          role: state.extra is Role ? state.extra as Role : null,
        ),
      ),
      GoRoute(
        path: '$permissionPath/create',
        redirect: (_, _) {
          if (authCubit.state.isLoading) return null;
          return authCubit.state.value?.canAccess(permissionCreatePermission) ==
                  true
              ? null
              : '/forbidden';
        },
        builder: (_, _) => const PermissionFormPage(),
      ),
      GoRoute(
        path: '$permissionPath/:id/edit',
        redirect: (_, state) {
          if (authCubit.state.isLoading) return null;
          if (state.extra is! Permission) return permissionPath;
          return authCubit.state.value?.canAccess(permissionUpdatePermission) ==
                  true
              ? null
              : '/forbidden';
        },
        builder: (_, state) => PermissionFormPage(
          permission: state.extra is Permission
              ? state.extra as Permission
              : null,
        ),
      ),
      GoRoute(path: '/forbidden', builder: (_, _) => const ForbiddenPage()),
    ],
  );
  final authSubscription = authCubit.stream.listen((_) => router.refresh());
  return (router: router, authSubscription: authSubscription);
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});
  @override
  Widget build(context) => Scaffold(
    appBar: AppBar(title: const Text('Access denied')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Your account does not have permission to use this feature. '
          'If you think this is a mistake, contact an administrator.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
