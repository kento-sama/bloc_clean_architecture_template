import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/responsive_layout.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/permissions/domain/entities/permission.dart';
import 'package:clean_bloc/features/permissions/presentation/cubits/permission_cubit.dart';
import 'package:clean_bloc/features/permissions/permission_config.dart';

class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PermissionCubit>().state;
    final user = context.watch<AuthCubit>().state.value;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: '/dashboard'),
        title: const Text(permissionTitle),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.hasError
          ? _LoadError(
              message: errorMessage(state.error!),
              onRetry: () => context.read<PermissionCubit>().load(),
            )
          : (state.value ?? []).isEmpty
          ? const Center(child: Text('No permissions yet.'))
          : ResponsiveLayout(
              mobileBuilder: (_) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.value!.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final permission = state.value![index];
                  return Card(
                    child: ListTile(
                      title: Text(permission.name),
                      subtitle: permission.guardName.isEmpty
                          ? null
                          : Text(permission.guardName),
                      trailing: _actions(context, user, permission),
                    ),
                  );
                },
              ),
              wideBuilder: (_) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Guard')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final permission in state.value!)
                      DataRow(
                        cells: [
                          DataCell(Text(permission.name)),
                          DataCell(Text(permission.guardName)),
                          DataCell(_actions(context, user, permission)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: user?.canAccess(permissionCreatePermission) == true
          ? FloatingActionButton.extended(
              onPressed: () => context.go('$permissionPath/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
    );
  }

  Widget _actions(BuildContext context, dynamic user, Permission permission) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user?.canAccess(permissionUpdatePermission) == true)
            IconButton(
              tooltip: 'Edit permission',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go(
                '$permissionPath/${permission.id}/edit',
                extra: permission,
              ),
            ),
          if (user?.canAccess(permissionDeletePermission) == true)
            IconButton(
              tooltip: 'Delete permission',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, permission),
            ),
        ],
      );

  Future<void> _delete(BuildContext context, Permission permission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete permission?'),
        content: Text('Delete "${permission.name}"? This cannot be undone.'),
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
      await context.read<PermissionCubit>().delete(permission.id);
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
