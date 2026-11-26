import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/permissions/permission_config.dart';
import 'package:clean_bloc/features/roles/domain/entities/role.dart';
import 'package:clean_bloc/features/roles/presentation/cubits/role_cubit.dart';
import 'package:clean_bloc/features/roles/presentation/screens/role_permissions_page.dart';
import 'package:clean_bloc/features/roles/role_config.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RoleCubit>().state;
    final user = context.watch<AuthCubit>().state.value;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: '/dashboard'),
        title: const Text(roleTitle),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.hasError
          ? _LoadError(
              message: errorMessage(state.error!),
              onRetry: () => context.read<RoleCubit>().load(),
            )
          : (state.value ?? []).isEmpty
          ? const Center(child: Text('No roles yet.'))
          : ResponsiveLayout(
              mobileBuilder: (_) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.value!.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final role = state.value![index];
                  return Card(
                    child: ListTile(
                      title: Text(role.name),
                      subtitle: role.permissions.isEmpty
                          ? null
                          : Text(role.permissions.join(', ')),
                      trailing: _actions(context, user, role),
                    ),
                  );
                },
              ),
              wideBuilder: (_) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Permissions')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final role in state.value!)
                      DataRow(
                        cells: [
                          DataCell(Text(role.name)),
                          DataCell(Text(role.permissions.join(', '))),
                          DataCell(_actions(context, user, role)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: user?.canAccess(roleCreatePermission) == true
          ? FloatingActionButton.extended(
              onPressed: () => context.go('$rolePath/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
    );
  }

  Widget _actions(BuildContext context, dynamic user, Role role) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (user?.canAccess(roleAssignPermissionsPermission) == true &&
          user?.canAccess(permissionViewPermission) == true)
        IconButton(
          tooltip: 'Manage role permissions',
          icon: const Icon(Icons.admin_panel_settings),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => RolePermissionsPage(role: role)),
          ),
        ),
      if (user?.canAccess(roleUpdatePermission) == true)
        IconButton(
          tooltip: 'Edit role',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('$rolePath/${role.id}/edit', extra: role),
        ),
      if (user?.canAccess(roleDeletePermission) == true)
        IconButton(
          tooltip: 'Delete role',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(context, role),
        ),
    ],
  );

  Future<void> _delete(BuildContext context, Role role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text('Delete "${role.name}"? This cannot be undone.'),
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
      await context.read<RoleCubit>().delete(role.id);
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
