import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/permissions/permission_config.dart';
import 'package:clean_bloc/features/roles/role_config.dart';
import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/presentation/cubits/user_cubit.dart';
import 'package:clean_bloc/features/users/presentation/screens/user_permissions_page.dart';
import 'package:clean_bloc/features/users/presentation/screens/user_roles_page.dart';
import 'package:clean_bloc/features/users/user_config.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserCubit>().state;
    final currentUser = context.watch<AuthCubit>().state.value;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: '/dashboard'),
        title: const Text(userTitle),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.hasError
          ? _LoadError(
              message: errorMessage(state.error!),
              onRetry: () => context.read<UserCubit>().load(),
            )
          : (state.value ?? []).isEmpty
          ? const Center(child: Text('No users yet.'))
          : ResponsiveLayout(
              mobileBuilder: (context) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.value!.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = state.value![index];
                  return Card(
                    child: ListTile(
                      title: Text(user.name),
                      subtitle: Text(
                        user.roles.isEmpty
                            ? user.email
                            : '${user.email} · ${user.roles.join(', ')}',
                      ),
                      trailing: _actions(context, currentUser, user),
                    ),
                  );
                },
              ),
              wideBuilder: (context) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Roles')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final user in state.value!)
                      DataRow(
                        cells: [
                          DataCell(Text(user.name)),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.roles.join(', '))),
                          DataCell(_actions(context, currentUser, user)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: currentUser?.canAccess(userCreatePermission) == true
          ? FloatingActionButton.extended(
              onPressed: () => context.go('$userPath/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
    );
  }

  Widget _actions(BuildContext context, dynamic currentUser, User user) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (currentUser?.canAccess(userAssignRolesPermission) == true &&
          currentUser?.canAccess(roleViewPermission) == true)
        IconButton(
          tooltip: 'Assign roles',
          icon: const Icon(Icons.manage_accounts_outlined),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => UserRolesPage(user: user)),
          ),
        ),
      if (currentUser?.canAccess(userAssignPermissionsPermission) == true &&
          currentUser?.canAccess(permissionViewPermission) == true)
        IconButton(
          tooltip: 'Manage direct permissions',
          icon: const Icon(Icons.key_outlined),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => UserPermissionsPage(user: user)),
          ),
        ),
      if (currentUser?.canAccess(userUpdatePermission) == true)
        IconButton(
          tooltip: 'Edit user',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('$userPath/${user.id}/edit', extra: user),
        ),
      if (currentUser?.canAccess(userDeletePermission) == true)
        IconButton(
          tooltip: 'Delete user',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(context, user),
        ),
    ],
  );

  Future<void> _delete(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('Delete "${user.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<UserCubit>().delete(user.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(error))));
      }
    }
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
