import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/responsive_choice_list.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/permissions/permission_config.dart';
import 'package:clean_bloc/features/permissions/presentation/cubits/permission_cubit.dart';
import 'package:clean_bloc/features/roles/domain/entities/role.dart';
import 'package:clean_bloc/features/roles/presentation/cubits/role_cubit.dart';
import 'package:clean_bloc/features/roles/role_config.dart';

class RolePermissionsPage extends StatefulWidget {
  const RolePermissionsPage({required this.role, super.key});

  final Role role;

  @override
  State<RolePermissionsPage> createState() => _RolePermissionsPageState();
}

class _RolePermissionsPageState extends State<RolePermissionsPage> {
  // Keep the visible selection local; update it only after the API succeeds.
  late final Set<String> _selected = widget.role.permissions.toSet();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.value;
    if (user?.canAccess(roleAssignPermissionsPermission) != true ||
        user?.canAccess(permissionViewPermission) != true) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallback: rolePath),
          title: Text('Permissions for ${widget.role.name}'),
        ),
        body: const Center(
          child: Text('You are not authorized to manage role permissions.'),
        ),
      );
    }

    final permissions = context.watch<PermissionCubit>().state;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: rolePath),
        title: Text('Permissions for ${widget.role.name}'),
      ),
      body: permissions.isLoading
          ? const Center(child: CircularProgressIndicator())
          : permissions.hasError
          ? _LoadError(
              message: errorMessage(permissions.error!),
              onRetry: () => context.read<PermissionCubit>().load(),
            )
          : Builder(
              builder: (_) {
                final items = permissions.value ?? const [];
                // Include already-assigned names even if they are absent from the
                // latest permission catalog, so they can still be revoked.
                final names = {
                  ...items.map((permission) => permission.name),
                  ..._selected,
                }.toList()..sort();
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Changes are applied immediately.'),
                    ),
                    Expanded(
                      child: names.isEmpty
                          ? const Center(
                              child: Text('No permissions available.'),
                            )
                          : ResponsiveChoiceList(
                              choices: names,
                              isSelected: _selected.contains,
                              isSaving: _isSaving,
                              onChanged: _changePermission,
                            ),
                    ),
                    if (_isSaving) const LinearProgressIndicator(),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _changePermission(String name, bool grant) async {
    setState(() => _isSaving = true);
    try {
      final cubit = context.read<RoleCubit>();
      if (grant) {
        await cubit.grantPermissions(widget.role.id, [name]);
      } else {
        await cubit.revokePermissions(widget.role.id, [name]);
      }
      if (!mounted) return;
      setState(() {
        if (grant) {
          _selected.add(name);
        } else {
          _selected.remove(name);
        }
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage(error))));
    }
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
