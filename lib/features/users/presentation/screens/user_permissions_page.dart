import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/error_message.dart';
import 'package:clean_bloc/core/presentation/app_back_button.dart';
import 'package:clean_bloc/core/presentation/responsive_choice_list.dart';
import 'package:clean_bloc/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:clean_bloc/features/permissions/permission_config.dart';
import 'package:clean_bloc/features/permissions/presentation/cubits/permission_cubit.dart';
import 'package:clean_bloc/features/users/domain/entities/user.dart';
import 'package:clean_bloc/features/users/presentation/cubits/user_cubit.dart';
import 'package:clean_bloc/features/users/user_config.dart';

class UserPermissionsPage extends StatefulWidget {
  const UserPermissionsPage({required this.user, super.key});

  final User user;

  @override
  State<UserPermissionsPage> createState() => _UserPermissionsPageState();
}

class _UserPermissionsPageState extends State<UserPermissionsPage> {
  // Track only direct grants; inherited role permissions are managed elsewhere.
  late final Set<String> _selected = widget.user.directPermissions.toSet();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthCubit>().state.value;
    if (currentUser?.canAccess(userAssignPermissionsPermission) != true ||
        currentUser?.canAccess(permissionViewPermission) != true) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallback: userPath),
          title: Text('Direct permissions for ${widget.user.name}'),
        ),
        body: const Center(
          child: Text('You are not authorized to manage user permissions.'),
        ),
      );
    }

    final permissions = context.watch<PermissionCubit>().state;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: userPath),
        title: Text('Direct permissions for ${widget.user.name}'),
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
                // Keep existing assignments visible even if the catalog has changed,
                // allowing an administrator to remove stale grants.
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
      final cubit = context.read<UserCubit>();
      if (grant) {
        await cubit.grantPermissions(widget.user.id, [name]);
      } else {
        await cubit.revokePermissions(widget.user.id, [name]);
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
